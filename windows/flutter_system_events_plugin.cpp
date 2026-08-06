#include "flutter_system_events_plugin.h"

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <netioapi.h>
#include <wininet.h>

#include <memory>
#include <optional>
#include <variant>

namespace flutter_system_events {

namespace {

constexpr char kMethodChannelName[] = "flutter_system_events";
constexpr char kEventChannelName[] = "flutter_system_events/events";
constexpr wchar_t kNetworkChangedMessageName[] =
    L"FlutterSystemEvents.NetworkChanged";

flutter::EncodableValue KeyboardHiddenEvent() {
  return flutter::EncodableValue(flutter::EncodableMap{
      {flutter::EncodableValue("type"), flutter::EncodableValue("keyboard")},
      {flutter::EncodableValue("visible"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("height"), flutter::EncodableValue(0)},
  });
}

flutter::EncodableValue LifecycleEvent(const char* state) {
  return flutter::EncodableValue(flutter::EncodableMap{
      {flutter::EncodableValue("type"), flutter::EncodableValue("lifecycle")},
      {flutter::EncodableValue("state"), flutter::EncodableValue(state)},
  });
}

flutter::EncodableValue NetworkEvent(bool online) {
  return flutter::EncodableValue(flutter::EncodableMap{
      {flutter::EncodableValue("type"), flutter::EncodableValue("network")},
      {flutter::EncodableValue("online"), flutter::EncodableValue(online)},
      {flutter::EncodableValue("networkType"),
       flutter::EncodableValue(online ? "other" : "none")},
  });
}

bool BoolValue(const flutter::EncodableMap& map, const char* key) {
  const auto enabled = map.find(flutter::EncodableValue(key));
  if (enabled == map.end()) {
    return false;
  }

  const auto* value = std::get_if<bool>(&enabled->second);
  return value != nullptr && *value;
}

void CALLBACK NetworkChangeCallback(PVOID caller_context,
                                    PMIB_IPINTERFACE_ROW row,
                                    MIB_NOTIFICATION_TYPE notification_type) {
  (void)row;
  (void)notification_type;

  auto* plugin = static_cast<FlutterSystemEventsPlugin*>(caller_context);
  plugin->PostNetworkChanged();
}

}  // namespace

// static
void FlutterSystemEventsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kMethodChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterSystemEventsPlugin>(registrar);
  auto plugin_pointer = plugin.get();

  channel->SetMethodCallHandler(
      [plugin_pointer](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  auto event_channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), kEventChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  event_channel->SetStreamHandler(
      std::make_unique<FlutterSystemEventsStreamHandler>(plugin_pointer));

  registrar->AddPlugin(std::move(plugin));
}

FlutterSystemEventsPlugin::FlutterSystemEventsPlugin() {}

FlutterSystemEventsPlugin::FlutterSystemEventsPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {}

FlutterSystemEventsPlugin::~FlutterSystemEventsPlugin() {
  StopNetwork();
  StopWindowProc();
}

void FlutterSystemEventsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("initialize") == 0) {
    config_ = ParseEventConfig(method_call.arguments());
    if (config_.keyboard) {
      EmitKeyboardHidden();
    }
    if (config_.lifecycle) {
      StartLifecycle();
    }
    if (config_.network) {
      StartNetwork();
    } else {
      StopNetwork();
    }
    StopWindowProcIfUnused();
    result->Success();
  } else if (method_call.method_name().compare("currentNetwork") == 0) {
    result->Success(CurrentNetwork());
  } else if (method_call.method_name().compare("dispose") == 0) {
    StopNetwork();
    StopWindowProc();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void FlutterSystemEventsPlugin::SetEventSink(
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> events) {
  events_ = std::move(events);
}

void FlutterSystemEventsPlugin::ClearEventSink() { events_.reset(); }

void FlutterSystemEventsPlugin::EmitKeyboardHidden() {
  if (events_) {
    events_->Success(KeyboardHiddenEvent());
  }
}

void FlutterSystemEventsPlugin::EmitLifecycle(const char* state) {
  if (events_) {
    events_->Success(LifecycleEvent(state));
  }
}

flutter::EncodableValue FlutterSystemEventsPlugin::CurrentNetwork() {
  DWORD flags = 0;
  const bool online = InternetGetConnectedState(&flags, 0) != FALSE;
  return NetworkEvent(online);
}

void FlutterSystemEventsPlugin::StartLifecycle() {
  StartWindowProc();
}

void FlutterSystemEventsPlugin::StartNetwork() {
  if (network_notification_handle_ != nullptr || registrar_ == nullptr ||
      registrar_->GetView() == nullptr) {
    return;
  }

  network_hwnd_ = registrar_->GetView()->GetNativeWindow();
  if (network_hwnd_ == nullptr) {
    return;
  }

  network_message_ = RegisterWindowMessageW(kNetworkChangedMessageName);
  if (network_message_ == 0) {
    network_hwnd_ = nullptr;
    return;
  }

  const auto status =
      NotifyIpInterfaceChange(AF_UNSPEC, NetworkChangeCallback, this, FALSE,
                              &network_notification_handle_);
  if (status != NO_ERROR) {
    network_notification_handle_ = nullptr;
    network_hwnd_ = nullptr;
    return;
  }

  StartWindowProc();
  EmitNetwork();
}

void FlutterSystemEventsPlugin::StopNetwork() {
  if (network_notification_handle_ != nullptr) {
    CancelMibChangeNotify2(network_notification_handle_);
    network_notification_handle_ = nullptr;
  }
  network_hwnd_ = nullptr;
}

void FlutterSystemEventsPlugin::EmitNetwork() {
  if (events_) {
    events_->Success(CurrentNetwork());
  }
}

void FlutterSystemEventsPlugin::PostNetworkChanged() {
  if (network_hwnd_ != nullptr && network_message_ != 0) {
    PostMessageW(network_hwnd_, network_message_, 0, 0);
  }
}

void FlutterSystemEventsPlugin::StartWindowProc() {
  if (registrar_ == nullptr || window_proc_id_.has_value()) {
    return;
  }

  window_proc_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowProc(hwnd, message, wparam, lparam);
      });
}

void FlutterSystemEventsPlugin::StopWindowProcIfUnused() {
  if (!config_.lifecycle && network_notification_handle_ == nullptr) {
    StopWindowProc();
  }
}

void FlutterSystemEventsPlugin::StopWindowProc() {
  if (registrar_ == nullptr || !window_proc_id_.has_value()) {
    return;
  }

  registrar_->UnregisterTopLevelWindowProcDelegate(*window_proc_id_);
  window_proc_id_.reset();
}

std::optional<LRESULT> FlutterSystemEventsPlugin::HandleWindowProc(
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  (void)hwnd;
  (void)lparam;

  if (!config_.lifecycle) {
    if (message == network_message_ && config_.network) {
      EmitNetwork();
    }
    return std::nullopt;
  }

  switch (message) {
    case WM_ACTIVATEAPP:
      EmitLifecycle(wparam ? "resumed" : "inactive");
      break;
    case WM_SIZE:
      if (wparam == SIZE_MINIMIZED) {
        EmitLifecycle("paused");
      }
      break;
    case WM_CLOSE:
    case WM_DESTROY:
      EmitLifecycle("detached");
      break;
    default:
      if (message == network_message_ && config_.network) {
        EmitNetwork();
      }
      break;
  }

  return std::nullopt;
}

FlutterSystemEventsPlugin::EventConfig
FlutterSystemEventsPlugin::ParseEventConfig(
    const flutter::EncodableValue *arguments) {
  if (arguments == nullptr) {
    return EventConfig();
  }

  const auto *map = std::get_if<flutter::EncodableMap>(arguments);
  if (map == nullptr) {
    return EventConfig();
  }

  EventConfig config;
  config.keyboard = BoolValue(*map, "keyboard");
  config.lifecycle = BoolValue(*map, "lifecycle");
  config.network = BoolValue(*map, "network");
  return config;
}

FlutterSystemEventsStreamHandler::FlutterSystemEventsStreamHandler(
    FlutterSystemEventsPlugin *plugin)
    : plugin_(plugin) {}

FlutterSystemEventsStreamHandler::~FlutterSystemEventsStreamHandler() {}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
FlutterSystemEventsStreamHandler::OnListenInternal(
    const flutter::EncodableValue *arguments,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&events) {
  plugin_->SetEventSink(std::move(events));
  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
FlutterSystemEventsStreamHandler::OnCancelInternal(
    const flutter::EncodableValue *arguments) {
  plugin_->ClearEventSink();
  return nullptr;
}

}  // namespace flutter_system_events

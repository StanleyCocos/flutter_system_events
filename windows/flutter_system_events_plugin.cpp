#include "flutter_system_events_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <variant>

namespace flutter_system_events {

namespace {

constexpr char kMethodChannelName[] = "flutter_system_events";
constexpr char kEventChannelName[] = "flutter_system_events/events";

flutter::EncodableValue KeyboardHiddenEvent() {
  return flutter::EncodableValue(flutter::EncodableMap{
      {flutter::EncodableValue("type"), flutter::EncodableValue("keyboard")},
      {flutter::EncodableValue("visible"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("height"), flutter::EncodableValue(0)},
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

}  // namespace

// static
void FlutterSystemEventsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kMethodChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterSystemEventsPlugin>();
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

FlutterSystemEventsPlugin::~FlutterSystemEventsPlugin() {}

void FlutterSystemEventsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("initialize") == 0) {
    config_ = ParseEventConfig(method_call.arguments());
    if (config_.keyboard) {
      EmitKeyboardHidden();
    }
    result->Success();
  } else if (method_call.method_name().compare("dispose") == 0) {
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

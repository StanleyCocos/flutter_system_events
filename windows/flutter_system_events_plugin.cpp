#include "flutter_system_events_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace flutter_system_events {

// static
void FlutterSystemEventsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_system_events",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterSystemEventsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterSystemEventsPlugin::FlutterSystemEventsPlugin() {}

FlutterSystemEventsPlugin::~FlutterSystemEventsPlugin() {}

void FlutterSystemEventsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("initialize") == 0) {
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_system_events

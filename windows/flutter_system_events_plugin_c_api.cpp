#include "include/flutter_system_events/flutter_system_events_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_system_events_plugin.h"

void FlutterSystemEventsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_system_events::FlutterSystemEventsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

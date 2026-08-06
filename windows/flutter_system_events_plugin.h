#ifndef FLUTTER_PLUGIN_FLUTTER_SYSTEM_EVENTS_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_SYSTEM_EVENTS_PLUGIN_H_

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <memory>
#include <optional>
#include <string>

#include <flutter/event_sink.h>
#include <flutter/event_stream_handler.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

namespace flutter_system_events {

class FlutterSystemEventsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterSystemEventsPlugin();
  explicit FlutterSystemEventsPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~FlutterSystemEventsPlugin();

  // Disallow copy and assign.
  FlutterSystemEventsPlugin(const FlutterSystemEventsPlugin&) = delete;
  FlutterSystemEventsPlugin& operator=(const FlutterSystemEventsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void SetEventSink(
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> events);
  void ClearEventSink();
  void PostNetworkChanged();

 private:
  struct EventConfig {
    bool keyboard = true;
    bool lifecycle = true;
    bool network = true;
  };

  void EmitKeyboardHidden();
  void EmitLifecycle(const char *state);
  flutter::EncodableValue CurrentNetwork();
  void EmitNetwork();
  void StartLifecycle();
  void StartNetwork();
  void StopNetwork();
  void StartWindowProc();
  void StopWindowProcIfUnused();
  void StopWindowProc();
  std::optional<LRESULT> HandleWindowProc(HWND hwnd,
                                          UINT message,
                                          WPARAM wparam,
                                          LPARAM lparam);
  EventConfig ParseEventConfig(const flutter::EncodableValue *arguments);

  flutter::PluginRegistrarWindows *registrar_ = nullptr;
  std::optional<int> window_proc_id_;
  HWND network_hwnd_ = nullptr;
  UINT network_message_ = 0;
  HANDLE network_notification_handle_ = nullptr;
  EventConfig config_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> events_;
};

class FlutterSystemEventsStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  explicit FlutterSystemEventsStreamHandler(FlutterSystemEventsPlugin *plugin);
  virtual ~FlutterSystemEventsStreamHandler();

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListenInternal(
      const flutter::EncodableValue *arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&events)
      override;

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancelInternal(const flutter::EncodableValue *arguments) override;

 private:
  FlutterSystemEventsPlugin *plugin_;
};

}  // namespace flutter_system_events

#endif  // FLUTTER_PLUGIN_FLUTTER_SYSTEM_EVENTS_PLUGIN_H_

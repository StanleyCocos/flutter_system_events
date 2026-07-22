#include "include/flutter_system_events/flutter_system_events_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>

#include "flutter_system_events_plugin_private.h"

#define FLUTTER_SYSTEM_EVENTS_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_system_events_plugin_get_type(), \
                              FlutterSystemEventsPlugin))

struct _FlutterSystemEventsPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FlutterSystemEventsPlugin, flutter_system_events_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void flutter_system_events_plugin_handle_method_call(
    FlutterSystemEventsPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "initialize") == 0 || strcmp(method, "dispose") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void flutter_system_events_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(flutter_system_events_plugin_parent_class)->dispose(object);
}

static void flutter_system_events_plugin_class_init(FlutterSystemEventsPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = flutter_system_events_plugin_dispose;
}

static void flutter_system_events_plugin_init(FlutterSystemEventsPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlutterSystemEventsPlugin* plugin = FLUTTER_SYSTEM_EVENTS_PLUGIN(user_data);
  flutter_system_events_plugin_handle_method_call(plugin, method_call);
}

void flutter_system_events_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlutterSystemEventsPlugin* plugin = FLUTTER_SYSTEM_EVENTS_PLUGIN(
      g_object_new(flutter_system_events_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "flutter_system_events",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}

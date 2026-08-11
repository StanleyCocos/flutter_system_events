#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <vector>

#include "flutter_system_events_plugin.h"

namespace flutter_system_events {
namespace test {

class RecordingEventSink : public flutter::EventSink<flutter::EncodableValue> {
 public:
  std::vector<flutter::EncodableValue> events;

 protected:
  void SuccessInternal(const flutter::EncodableValue* event = nullptr) override {
    if (event != nullptr) {
      events.push_back(*event);
    }
  }

  void ErrorInternal(const std::string& error_code,
                     const std::string& error_message,
                     const flutter::EncodableValue* error_details) override {
    (void)error_code;
    (void)error_message;
    (void)error_details;
  }

  void EndOfStreamInternal() override {}
};

TEST(FlutterSystemEventsPlugin, Initialize) {
  FlutterSystemEventsPlugin plugin;
  bool success = false;

  plugin.HandleMethodCall(
      flutter::MethodCall<flutter::EncodableValue>(
          "initialize", std::make_unique<flutter::EncodableValue>()),
      std::make_unique<flutter::MethodResultFunctions<>>(
          [&success](const flutter::EncodableValue* result) { success = true; },
          nullptr, nullptr));

  EXPECT_TRUE(success);
}

TEST(FlutterSystemEventsPlugin, InitializeWithKeyboardDisabled) {
  FlutterSystemEventsPlugin plugin;
  bool success = false;
  flutter::EncodableMap arguments = {
      {flutter::EncodableValue("keyboard"), flutter::EncodableValue(false)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall<flutter::EncodableValue>(
          "initialize",
          std::make_unique<flutter::EncodableValue>(arguments)),
      std::make_unique<flutter::MethodResultFunctions<>>(
          [&success](const flutter::EncodableValue* result) { success = true; },
          nullptr, nullptr));

  EXPECT_TRUE(success);
}

TEST(FlutterSystemEventsPlugin, InitializeAcceptsLifecycleConfig) {
  FlutterSystemEventsPlugin plugin;
  bool success = false;
  flutter::EncodableMap arguments = {
      {flutter::EncodableValue("keyboard"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("lifecycle"), flutter::EncodableValue(true)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall<flutter::EncodableValue>(
          "initialize",
          std::make_unique<flutter::EncodableValue>(arguments)),
      std::make_unique<flutter::MethodResultFunctions<>>(
          [&success](const flutter::EncodableValue* result) { success = true; },
          nullptr, nullptr));

  EXPECT_TRUE(success);
}

TEST(FlutterSystemEventsPlugin, InitializeAcceptsNetworkConfig) {
  FlutterSystemEventsPlugin plugin;
  bool success = false;
  flutter::EncodableMap arguments = {
      {flutter::EncodableValue("keyboard"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("lifecycle"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("network"), flutter::EncodableValue(true)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall<flutter::EncodableValue>(
          "initialize",
          std::make_unique<flutter::EncodableValue>(arguments)),
      std::make_unique<flutter::MethodResultFunctions<>>(
          [&success](const flutter::EncodableValue* result) { success = true; },
          nullptr, nullptr));

  EXPECT_TRUE(success);
}

TEST(FlutterSystemEventsPlugin, InitializeWithNetworkDoesNotEmitInitialEvent) {
  FlutterSystemEventsPlugin plugin;
  auto events = std::make_unique<RecordingEventSink>();
  auto* recorded_events = events.get();
  plugin.SetEventSink(std::move(events));
  bool success = false;
  flutter::EncodableMap arguments = {
      {flutter::EncodableValue("keyboard"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("lifecycle"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("network"), flutter::EncodableValue(true)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall<flutter::EncodableValue>(
          "initialize",
          std::make_unique<flutter::EncodableValue>(arguments)),
      std::make_unique<flutter::MethodResultFunctions<>>(
          [&success](const flutter::EncodableValue* result) { success = true; },
          nullptr, nullptr));

  EXPECT_TRUE(success);
  EXPECT_TRUE(recorded_events->events.empty());
}

TEST(FlutterSystemEventsPlugin, InitializeWithKeyboardDoesNotEmitHiddenEvent) {
  FlutterSystemEventsPlugin plugin;
  auto events = std::make_unique<RecordingEventSink>();
  auto* recorded_events = events.get();
  plugin.SetEventSink(std::move(events));
  bool success = false;
  flutter::EncodableMap arguments = {
      {flutter::EncodableValue("keyboard"), flutter::EncodableValue(true)},
      {flutter::EncodableValue("lifecycle"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("network"), flutter::EncodableValue(false)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall<flutter::EncodableValue>(
          "initialize",
          std::make_unique<flutter::EncodableValue>(arguments)),
      std::make_unique<flutter::MethodResultFunctions<>>(
          [&success](const flutter::EncodableValue* result) { success = true; },
          nullptr, nullptr));

  EXPECT_TRUE(success);
  EXPECT_TRUE(recorded_events->events.empty());
}

TEST(FlutterSystemEventsPlugin, WindowNetworkMessagesDoNotEmitUnchangedEvent) {
  FlutterSystemEventsPlugin plugin;
  auto events = std::make_unique<RecordingEventSink>();
  auto* recorded_events = events.get();
  plugin.SetEventSink(std::move(events));
  bool success = false;
  flutter::EncodableMap arguments = {
      {flutter::EncodableValue("keyboard"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("lifecycle"), flutter::EncodableValue(false)},
      {flutter::EncodableValue("network"), flutter::EncodableValue(true)},
  };

  plugin.HandleMethodCall(
      flutter::MethodCall<flutter::EncodableValue>(
          "initialize",
          std::make_unique<flutter::EncodableValue>(arguments)),
      std::make_unique<flutter::MethodResultFunctions<>>(
          [&success](const flutter::EncodableValue* result) { success = true; },
          nullptr, nullptr));
  plugin.HandleWindowProcForTest(nullptr, WM_DEVICECHANGE, 0, 0);
  plugin.HandleWindowProcForTest(nullptr, WM_SETTINGCHANGE, 0, 0);

  EXPECT_TRUE(success);
  EXPECT_TRUE(recorded_events->events.empty());
}

TEST(FlutterSystemEventsPlugin, CurrentNetworkReturnsNetworkEvent) {
  FlutterSystemEventsPlugin plugin;
  bool success = false;

  plugin.HandleMethodCall(
      flutter::MethodCall<flutter::EncodableValue>(
          "currentNetwork", std::make_unique<flutter::EncodableValue>()),
      std::make_unique<flutter::MethodResultFunctions<>>(
          [&success](const flutter::EncodableValue* result) {
            success = true;
            const auto* event = std::get_if<flutter::EncodableMap>(result);
            ASSERT_NE(event, nullptr);
            EXPECT_EQ(event->at(flutter::EncodableValue("type")),
                      flutter::EncodableValue("network"));
            EXPECT_TRUE(event->find(flutter::EncodableValue("online")) !=
                        event->end());
            EXPECT_TRUE(event->find(flutter::EncodableValue("networkType")) !=
                        event->end());
          },
          nullptr, nullptr));

  EXPECT_TRUE(success);
}

}  // namespace test
}  // namespace flutter_system_events

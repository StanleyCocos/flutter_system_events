#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>

#include <memory>

#include "flutter_system_events_plugin.h"

namespace flutter_system_events {
namespace test {

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

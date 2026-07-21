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

}  // namespace test
}  // namespace flutter_system_events

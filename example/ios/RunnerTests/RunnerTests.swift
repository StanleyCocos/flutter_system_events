import Flutter
import XCTest

@testable import flutter_system_events

class RunnerTests: XCTestCase {
  func testInitialize() {
    let plugin = FlutterSystemEventsPlugin()
    let call = FlutterMethodCall(methodName: "initialize", arguments: [])
    let resultExpectation = expectation(description: "result block must be called.")

    plugin.handle(call) { result in
      XCTAssertNil(result)
      resultExpectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }

  func testScreenshotEnabledEmitsScreenshotEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: [String: Any]?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value as? [String: Any]
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["screenshot": true])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    NotificationCenter.default.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)

    XCTAssertEqual(event?["type"] as? String, "screenshot")
  }

  func testScreenshotDisabledDoesNotEmitScreenshotEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: Any?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["screenshot": false])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    NotificationCenter.default.post(name: UIApplication.userDidTakeScreenshotNotification, object: nil)

    XCTAssertNil(event)
  }
}

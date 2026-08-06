import FlutterMacOS
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

  func testKeyboardInitializeEmitsHiddenEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: [String: Any]?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value as? [String: Any]
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["keyboard": true])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    XCTAssertEqual(event?["type"] as? String, "keyboard")
    XCTAssertEqual(event?["visible"] as? Bool, false)
    XCTAssertEqual(event?["height"] as? Int, 0)
  }

  func testKeyboardDisabledDoesNotEmitEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: Any?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["keyboard": false])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    XCTAssertNil(event)
  }

  func testLifecycleInitializeObservesActiveEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: [String: Any]?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value as? [String: Any]
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["lifecycle": true])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)

    XCTAssertEqual(event?["type"] as? String, "lifecycle")
    XCTAssertEqual(event?["state"] as? String, "resumed")
  }

  func testLifecycleDisabledDoesNotEmitEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: Any?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["lifecycle": false])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)

    XCTAssertNil(event)
  }

  func testCurrentNetworkReturnsNetworkEvent() {
    let plugin = FlutterSystemEventsPlugin()
    let resultExpectation = expectation(description: "currentNetwork returns.")

    plugin.handle(FlutterMethodCall(methodName: "currentNetwork", arguments: nil)) { result in
      let event = result as? [String: Any]

      XCTAssertEqual(event?["type"] as? String, "network")
      XCTAssertNotNil(event?["online"] as? Bool)
      XCTAssertNotNil(event?["networkType"] as? String)
      resultExpectation.fulfill()
    }

    waitForExpectations(timeout: 5)
  }
}

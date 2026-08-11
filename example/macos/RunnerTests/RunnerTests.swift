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

  func testKeyboardInitializeDoesNotEmitHiddenEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: Any?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["keyboard": true])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    XCTAssertNil(event)
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

  func testTimeInitializeObservesTimezoneEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: [String: Any]?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value as? [String: Any]
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["time": true])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    NotificationCenter.default.post(name: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil)

    XCTAssertEqual(event?["type"] as? String, "time")
    XCTAssertEqual(event?["reason"] as? String, "timezoneChanged")
  }

  func testTimeDisabledDoesNotEmitEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: Any?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["time": false])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    NotificationCenter.default.post(name: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil)

    XCTAssertNil(event)
  }

  func testCurrentBatteryReturnsBatteryEvent() {
    let plugin = FlutterSystemEventsPlugin()

    plugin.handle(FlutterMethodCall(methodName: "currentBattery", arguments: nil)) { result in
      let event = result as? [String: Any]

      XCTAssertEqual(event?["type"] as? String, "battery")
      XCTAssertNotNil(event?["level"] as? Int)
      XCTAssertNotNil(event?["charging"] as? Bool)
      XCTAssertNotNil(event?["state"] as? String)
    }
  }

  func testCurrentOrientationReturnsOrientationEvent() {
    let plugin = FlutterSystemEventsPlugin()

    plugin.handle(FlutterMethodCall(methodName: "currentOrientation", arguments: nil)) { result in
      let event = result as? [String: Any]

      XCTAssertEqual(event?["type"] as? String, "orientation")
      XCTAssertNotNil(event?["orientation"] as? String)
    }
  }

  func testOrientationInitializeDoesNotEmitCurrentEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: Any?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["orientation": true])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    XCTAssertNil(event)
  }

  func testNetworkSnapshotComparesConnectivityStateOnly() {
    XCTAssertEqual(
      NetworkSnapshot(event: ["type": "network", "online": true, "networkType": "wifi"]),
      NetworkSnapshot(event: ["type": "network", "online": true, "networkType": "wifi"])
    )
    XCTAssertNotEqual(
      NetworkSnapshot(event: ["type": "network", "online": true, "networkType": "wifi"]),
      NetworkSnapshot(event: ["type": "network", "online": false, "networkType": "none"])
    )
  }

  func testBatterySnapshotComparesBatteryStateOnly() {
    XCTAssertEqual(
      BatterySnapshot(event: ["type": "battery", "level": 100, "charging": true, "state": "full"]),
      BatterySnapshot(event: ["type": "battery", "level": 100, "charging": true, "state": "full"])
    )
  }

  func testOrientationSnapshotComparesOrientationOnly() {
    XCTAssertEqual(
      OrientationSnapshot(event: ["type": "orientation", "orientation": "portraitUp"]),
      OrientationSnapshot(event: ["type": "orientation", "orientation": "portraitUp"])
    )
  }
}

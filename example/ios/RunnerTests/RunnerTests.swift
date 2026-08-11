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

  func testThermalEnabledDoesNotEmitInitialOrUnchangedEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: Any?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["thermal": true])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    NotificationCenter.default.post(name: ProcessInfo.thermalStateDidChangeNotification, object: nil)

    XCTAssertNil(event)
  }

  func testThermalDisabledDoesNotEmitThermalEvent() {
    let plugin = FlutterSystemEventsPlugin()
    var event: Any?

    _ = plugin.onListen(withArguments: nil) { value in
      event = value
    }

    let call = FlutterMethodCall(methodName: "initialize", arguments: ["thermal": false])
    plugin.handle(call) { result in
      XCTAssertNil(result)
    }

    NotificationCenter.default.post(name: ProcessInfo.thermalStateDidChangeNotification, object: nil)

    XCTAssertNil(event)
  }

  func testThermalStateEventMapsProcessInfoStates() {
    XCTAssertEqual(thermalEvent(from: .nominal)["state"] as? String, "nominal")
    XCTAssertEqual(thermalEvent(from: .fair)["state"] as? String, "fair")
    XCTAssertEqual(thermalEvent(from: .serious)["state"] as? String, "serious")
    XCTAssertEqual(thermalEvent(from: .critical)["state"] as? String, "critical")
  }

  func testCurrentThermalReturnsThermalEvent() {
    let plugin = FlutterSystemEventsPlugin()

    plugin.handle(FlutterMethodCall(methodName: "currentThermal", arguments: nil)) { result in
      let event = result as? [String: Any]

      XCTAssertEqual(event?["type"] as? String, "thermal")
      XCTAssertNotNil(event?["state"] as? String)
    }
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

  func testThermalSnapshotComparesThermalStateOnly() {
    XCTAssertEqual(
      ThermalSnapshot(event: ["type": "thermal", "state": "nominal"]),
      ThermalSnapshot(event: ["type": "thermal", "state": "nominal"])
    )
  }
}

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
}

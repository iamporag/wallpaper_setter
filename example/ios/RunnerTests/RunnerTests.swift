import Flutter
import UIKit
import XCTest


@testable import wallpaper_setter

// iOS unit tests for the v2 wallpaper_setter plugin contract.
// iOS cannot set wallpapers programmatically, so every wallpaper-setting call
// must return an explicit `unsupported` result instead of crashing or
// pretending to succeed.

class RunnerTests: XCTestCase {

  private func resultMap(
    for method: String,
    arguments: [String: Any]? = nil
  ) -> [String: Any] {
    let plugin = WallpaperSetterPlugin()
    let call = FlutterMethodCall(methodName: method, arguments: arguments)

    let resultExpectation = expectation(description: "result block must be called.")
    var captured: [String: Any]? = nil
    plugin.handle(call) { result in
      captured = result as? [String: Any]
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
    return captured ?? [:]
  }

  func testSetWallpaper_returnsUnsupported() {
    let result = resultMap(
      for: "setWallpaper",
      arguments: ["path": "/tmp/wallpaper.png", "target": "home"]
    )

    XCTAssertEqual(result["isSuccess"] as? Bool, false)
    XCTAssertEqual(result["error"] as? String, "unsupported")
  }

  func testGetCapabilities_reportsNoWallpaperSettingSupport() {
    let result = resultMap(for: "getCapabilities")

    XCTAssertEqual(result["home"] as? Bool, false)
    XCTAssertEqual(result["lock"] as? Bool, false)
    XCTAssertEqual(result["both"] as? Bool, false)
    XCTAssertEqual(result["capturedWidget"] as? Bool, false)
    XCTAssertEqual(result["directImageSources"] as? Bool, false)
  }

  func testUseAsImage_withMissingPath_returnsInvalidImage() {
    let result = resultMap(for: "useAsImage")

    XCTAssertEqual(result["isSuccess"] as? Bool, false)
    XCTAssertEqual(result["error"] as? String, "invalidImage")
  }

  func testGetScreenInfo_returnsScreenDetails() {
    let result = resultMap(for: "getScreenInfo")

    XCTAssertNotNil(result["width"])
    XCTAssertNotNil(result["height"])
    XCTAssertNotNil(result["pixelDensity"])
    XCTAssertNotNil(result["orientation"])
  }

}
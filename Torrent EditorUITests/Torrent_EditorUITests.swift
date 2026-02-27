//
//  Torrent_EditorUITests.swift
//  Torrent EditorUITests
//
//  Created by Ashley Connor on 07/12/2025.
//

import XCTest

final class Torrent_EditorUITests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testTabBarIsVisible() throws {
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(app.radioButtons["Info"].exists)
    XCTAssertTrue(app.radioButtons["Trackers"].exists)
    XCTAssertTrue(app.radioButtons["Files"].exists)
  }

  @MainActor
  func testSwitchingToTrackersTabShowsPrimaryTrackerSection() throws {
    let app = XCUIApplication()
    app.launch()

    app.radioButtons["Trackers"].click()

    XCTAssertTrue(app.staticTexts["Primary Tracker"].exists)
  }

  @MainActor
  func testSwitchingToFilesTabShowsEmptyState() throws {
    let app = XCUIApplication()
    app.launch()

    app.radioButtons["Files"].click()

    XCTAssertTrue(app.staticTexts["No Files Added"].exists)
  }

  @MainActor
  func testOpenTorrentFileShowsMetadata() throws {
    let torrentURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("testdata/ubuntukylin-24.04.4-desktop-amd64.iso.torrent")

    let app = XCUIApplication()
    app.launchEnvironment["UITestTorrentFilePath"] = torrentURL.path
    app.launch()

    // Name field should reflect the torrent's info.name
    let nameField = app.textFields["torrentName"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 5))
    XCTAssertEqual(nameField.value as? String, "ubuntukylin-24.04.4-desktop-amd64.iso")

    // Announce URL field should show the primary tracker
    let announceField = app.textFields["announceURL"]
    XCTAssertEqual(announceField.value as? String, "https://torrent.ubuntu.com/announce")

    // Torrent Information section should show 1 file
    XCTAssertTrue(app.staticTexts["1"].exists)
  }

  @MainActor
  func testLaunchPerformance() throws {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      XCUIApplication().launch()
    }
  }
}

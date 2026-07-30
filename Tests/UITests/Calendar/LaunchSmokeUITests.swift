//
//  LaunchSmokeUITests.swift
//  GalacticCalendarUITests
//
//  QA-01 — Launch / Home.
//

import XCTest

final class LaunchSmokeUITests: SmokeUITestCase {

    func testLaunchOpensHomeScreen() {
        XCTAssertTrue(element(SmokeAccessibilityID.homeScreen).exists)
        XCTAssertTrue(element(SmokeAccessibilityID.homeMenu).exists)
        XCTAssertTrue(element(SmokeAccessibilityID.homeToday).exists)
        XCTAssertTrue(element(SmokeAccessibilityID.homeMonthTitle).exists)
        XCTAssertTrue(element(SmokeAccessibilityID.homeYearTitle).exists)
        XCTAssertTrue(element(SmokeAccessibilityID.calendarGrid).exists)
    }
}

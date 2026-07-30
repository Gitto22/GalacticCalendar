//
//  CalendarAppearanceManagerTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// PB-05.1 — CalendarAppearanceManager owns month / background / contrast state.
final class CalendarAppearanceManagerTests: XCTestCase {

    func testPrepareDisplayedMonthUpdatesActiveMonthAndYear() {
        let appearance = CalendarAppearanceManager()
        appearance.prepareDisplayedMonth(3, year: 2026)
        XCTAssertEqual(appearance.activeMonthNumber, 3)
        XCTAssertEqual(appearance.activeYear, 2026)
        XCTAssertEqual(appearance.activeMonthBackground, .march)
        XCTAssertEqual(appearance.activeMonthBackgroundName, "March")
    }

    func testPrepareDisplayedMonthIgnoresInvalidMonth() {
        let appearance = CalendarAppearanceManager()
        appearance.prepareDisplayedMonth(7, year: 2026)
        appearance.prepareDisplayedMonth(0, year: 2030)
        XCTAssertEqual(appearance.activeMonthNumber, 7)
        XCTAssertEqual(appearance.activeYear, 2026)
    }

    func testBackgroundAssetNameFallsBackToJanuary() {
        let appearance = CalendarAppearanceManager()
        XCTAssertEqual(appearance.backgroundAssetName(for: 99), "January")
        XCTAssertEqual(appearance.backgroundAssetName(for: 2), "February")
    }

    func testDisplayedMonthAndYearTextAreNonEmpty() {
        let appearance = CalendarAppearanceManager()
        appearance.prepareDisplayedMonth(11, year: 2026)
        XCTAssertFalse(appearance.displayedMonthName().isEmpty)
        XCTAssertFalse(appearance.displayedYearText().isEmpty)
    }

    func testActiveContrastProfileTracksMonth() {
        let appearance = CalendarAppearanceManager()
        appearance.prepareDisplayedMonth(3, year: 2026)
        XCTAssertEqual(appearance.activeMonthContrastProfile, .strong)
        appearance.prepareDisplayedMonth(2, year: 2026)
        XCTAssertEqual(appearance.activeMonthContrastProfile, .standard)
    }
}

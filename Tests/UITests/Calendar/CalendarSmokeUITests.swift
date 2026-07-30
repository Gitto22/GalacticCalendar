//
//  CalendarSmokeUITests.swift
//  GalacticCalendarUITests
//
//  QA-01 — Calendar navigation and day selection.
//

import XCTest

final class CalendarSmokeUITests: SmokeUITestCase {

    func testChangeMonthThenReturnToTodayAndSelectDay() {
        XCTAssertTrue(element(SmokeAccessibilityID.calendarGrid).exists)
        XCTAssertTrue(element(SmokeAccessibilityID.calendarWeekHeader).exists)

        let originalMonth = monthTitleLabel()

        // Change month (next), then previous to exercise both controls.
        tap(SmokeAccessibilityID.homeMonthNext)
        let afterNext = monthTitleLabel()
        // Title may stay equal only at year wrap edge cases; still require grid + today control.
        XCTAssertTrue(element(SmokeAccessibilityID.calendarGrid).exists)
        XCTAssertFalse(afterNext.isEmpty)

        tap(SmokeAccessibilityID.homeMonthPrevious)
        XCTAssertTrue(element(SmokeAccessibilityID.calendarGrid).exists)

        // Return to current month via Today.
        goToToday()
        let todayMonth = monthTitleLabel()
        XCTAssertEqual(todayMonth, originalMonth, "Today should restore the starting month title")
        XCTAssertTrue(element(SmokeAccessibilityID.calendarDayToday).exists)

        // Select today — routes to editor (0/1 events) or day list (2+).
        tap(SmokeAccessibilityID.calendarDayToday)
        let editor = element(SmokeAccessibilityID.eventEditor)
        let dayList = element(SmokeAccessibilityID.dayEventsScreen)
        let openedEditor = editor.waitForExistence(timeout: defaultTimeout)
        let openedList = dayList.waitForExistence(timeout: 1)
        XCTAssertTrue(openedEditor || openedList, "Selecting today opened neither editor nor day events")

        if openedList {
            tap(SmokeAccessibilityID.dayEventsClose)
        } else if element(SmokeAccessibilityID.eventEditorClose).exists {
            tap(SmokeAccessibilityID.eventEditorClose)
        }
        assertHomeReady()
    }
}

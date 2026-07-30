//
//  DayEventsSmokeUITests.swift
//  GalacticCalendarUITests
//
//  QA-01 — Day Events list.
//

import XCTest

final class DayEventsSmokeUITests: SmokeUITestCase {

    func testOpenDayEventsListAndClose() {
        openDayEventsForToday()

        XCTAssertTrue(element(SmokeAccessibilityID.dayEventsScreen).exists)
        XCTAssertTrue(element(SmokeAccessibilityID.dayEventsTitle).exists)
        XCTAssertTrue(element(SmokeAccessibilityID.dayEventsNewEvent).exists)

        let row = firstEventRow()
        XCTAssertTrue(
            row.waitForExistence(timeout: defaultTimeout),
            "Day events list should show at least one event row"
        )

        tap(SmokeAccessibilityID.dayEventsClose)
        assertHomeReady()
    }
}

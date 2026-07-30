//
//  SmartAgendaSmokeUITests.swift
//  GalacticCalendarUITests
//
//  QA-01 — Smart Agenda.
//

import XCTest

final class SmartAgendaSmokeUITests: SmokeUITestCase {

    func testOpenSmartAgendaLoadsAndCloses() {
        openSmartAgenda()

        XCTAssertTrue(element(SmokeAccessibilityID.smartAgendaScreen).exists)
        XCTAssertTrue(
            element(SmokeAccessibilityID.agendaSummaryHeader).waitForExistence(timeout: defaultTimeout),
            "Agenda summary did not load"
        )
        XCTAssertTrue(element(SmokeAccessibilityID.agendaClose).exists)
        XCTAssertTrue(element(SmokeAccessibilityID.agendaAddEvent).exists)

        tap(SmokeAccessibilityID.agendaClose)
        assertHomeReady()
    }
}

//
//  UniverseSmokeUITests.swift
//  GalacticCalendarUITests
//
//  QA-01 — Universe daily message on Home.
//

import XCTest

final class UniverseSmokeUITests: SmokeUITestCase {

    func testDailyUniverseMessageAppearsOnHome() {
        let card = element(SmokeAccessibilityID.universeMessageCard)
        XCTAssertTrue(
            card.waitForExistence(timeout: defaultTimeout),
            "Universe message card missing on Home"
        )
        // Accessibility value carries the message body (combined element).
        let value = card.value as? String ?? ""
        let label = card.label
        XCTAssertFalse(
            label.isEmpty && value.isEmpty,
            "Universe message card has no accessible content"
        )
    }
}

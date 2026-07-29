//
//  RepeatRuleTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for ``RepeatRule`` persistence encoding and decoding.
final class RepeatRuleTests: XCTestCase {

    // MARK: - Presets

    func testEditorSelectableRulesMatchApprovedFrequencies() {
        let frequencies = RepeatRule.editorSelectableRules.map(\.frequency)
        XCTAssertEqual(
            frequencies,
            [.none, .daily, .weekly, .monthly, .yearly]
        )
    }

    // MARK: - Plain Persistence

    func testEncodeDefaultRuleUsesFrequencyRawValue() {
        XCTAssertEqual(RepeatRule.none.encodeForPersistence(), "none")
        XCTAssertEqual(RepeatRule.daily.encodeForPersistence(), "daily")
        XCTAssertEqual(RepeatRule.weekly.encodeForPersistence(), "weekly")
        XCTAssertEqual(RepeatRule.monthly.encodeForPersistence(), "monthly")
        XCTAssertEqual(RepeatRule.yearly.encodeForPersistence(), "yearly")
    }

    func testDecodeLegacyFrequencyStrings() {
        XCTAssertEqual(RepeatRule.decodeFromPersistence("none"), .none)
        XCTAssertEqual(RepeatRule.decodeFromPersistence("daily"), .daily)
        XCTAssertEqual(RepeatRule.decodeFromPersistence("weekly"), .weekly)
        XCTAssertEqual(RepeatRule.decodeFromPersistence("monthly"), .monthly)
        XCTAssertEqual(RepeatRule.decodeFromPersistence("yearly"), .yearly)
    }

    func testDecodeUnknownStringFallsBackToNone() {
        XCTAssertEqual(RepeatRule.decodeFromPersistence("not-a-rule"), .none)
        XCTAssertEqual(RepeatRule.decodeFromPersistence(""), .none)
    }

    // MARK: - Versioned Envelope

    func testEncodeDecodeRoundTripWithIntervalAndEndDate() throws {
        let end = Date(timeIntervalSince1970: 1_900_000_000)
        let original = RepeatRule(
            frequency: .weekly,
            interval: 2,
            endDate: end
        )

        let raw = original.encodeForPersistence()
        XCTAssertNil(RepeatFrequency(rawValue: raw))

        let decoded = RepeatRule.decodeFromPersistence(raw)
        XCTAssertEqual(decoded.frequency, .weekly)
        XCTAssertEqual(decoded.interval, 2)
        XCTAssertEqual(
            decoded.endDate?.timeIntervalSince1970 ?? 0,
            end.timeIntervalSince1970,
            accuracy: 0.001
        )
        XCTAssertNil(decoded.customConfiguration)
    }

    func testIsRecurring() {
        XCTAssertFalse(RepeatRule.none.isRecurring)
        XCTAssertTrue(RepeatRule.daily.isRecurring)
        XCTAssertTrue(
            RepeatRule(
                frequency: .none,
                customConfiguration: RepeatCustomConfiguration(payload: Data([1]))
            ).isRecurring
        )
    }
}

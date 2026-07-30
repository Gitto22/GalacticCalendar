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
            [.none, .daily, .weekly, .biweekly, .monthly, .yearly]
        )
    }

    // MARK: - Plain Persistence

    func testEncodeDefaultRuleUsesFrequencyRawValue() throws {
        XCTAssertEqual(try RepeatRule.none.encodeForPersistence(), "none")
        XCTAssertEqual(try RepeatRule.daily.encodeForPersistence(), "daily")
        XCTAssertEqual(try RepeatRule.weekly.encodeForPersistence(), "weekly")
        XCTAssertEqual(try RepeatRule.monthly.encodeForPersistence(), "monthly")
        XCTAssertEqual(try RepeatRule.yearly.encodeForPersistence(), "yearly")
        XCTAssertEqual(try RepeatRule.biweekly.encodeForPersistence(), "biweekly")
        XCTAssertEqual(try RepeatRule.decodeFromPersistence("biweekly"), .biweekly)
    }

    func testDecodeLegacyFrequencyStrings() throws {
        XCTAssertEqual(try RepeatRule.decodeFromPersistence("none"), .none)
        XCTAssertEqual(try RepeatRule.decodeFromPersistence("daily"), .daily)
        XCTAssertEqual(try RepeatRule.decodeFromPersistence("weekly"), .weekly)
        XCTAssertEqual(try RepeatRule.decodeFromPersistence("biweekly"), .biweekly)
        XCTAssertEqual(try RepeatRule.decodeFromPersistence("monthly"), .monthly)
        XCTAssertEqual(try RepeatRule.decodeFromPersistence("yearly"), .yearly)
    }

    func testDecodeEmptyStringIsNone() throws {
        XCTAssertEqual(try RepeatRule.decodeFromPersistence(""), .none)
    }

    func testDecodeUnknownStringThrows() {
        XCTAssertThrowsError(try RepeatRule.decodeFromPersistence("not-a-rule")) { error in
            XCTAssertEqual(error as? EventPersistenceCodecError, .decodingFailed)
        }
    }

    // MARK: - Versioned Envelope

    func testEncodeDecodeRoundTripWithIntervalAndEndDate() throws {
        let end = Date(timeIntervalSince1970: 1_900_000_000)
        let original = RepeatRule(
            frequency: .weekly,
            interval: 2,
            endDate: end
        )

        let raw = try original.encodeForPersistence()
        XCTAssertNil(RepeatFrequency(rawValue: raw))

        let decoded = try RepeatRule.decodeFromPersistence(raw)
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

    func testAsRecurrenceRuleBridge() {
        let rule = RepeatRule(frequency: .weekly, interval: 2, occurrenceCount: 4)
        let canonical = rule.asRecurrenceRule
        XCTAssertEqual(canonical.frequency, .weekly)
        XCTAssertEqual(canonical.interval, 2)
        XCTAssertEqual(canonical.end, .after(count: 4))
    }
}

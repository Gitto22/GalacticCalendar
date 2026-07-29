//
//  EventEntityMapperTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for ``EventEntityMapper``.
final class EventEntityMapperTests: XCTestCase {

    // MARK: - Round Trip

    func testMakeEntityAndMakeDomainRoundTrip() {
        let end = Date(timeIntervalSince1970: 1_950_000_000)
        let original = Event(
            id: UUID(),
            title: "Mapped",
            description: "Notes",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            endDate: Date(timeIntervalSince1970: 1_900_003_600),
            timeZoneIdentifier: "Europe/Madrid",
            reminder: Date(timeIntervalSince1970: 1_899_991_000),
            repeatRule: RepeatRule(frequency: .weekly, interval: 2, endDate: end),
            category: .personal,
            priority: .high,
            status: .completed,
            color: .orange,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_850_000_000)
        )

        let entity = EventEntityMapper.makeEntity(from: original)
        let restored = EventEntityMapper.makeDomain(from: entity)

        XCTAssertEqual(restored, original)
    }

    // MARK: - Apply

    func testApplyUpdatesMutableFields() {
        let original = Event(
            title: "Before",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .green
        )
        let entity = EventEntityMapper.makeEntity(from: original)

        let updated = Event(
            id: original.id,
            title: "After",
            description: "Changed",
            date: Date(timeIntervalSince1970: 1_910_000_000),
            endDate: Date(timeIntervalSince1970: 1_910_007_200),
            timeZoneIdentifier: "UTC",
            reminder: Date(timeIntervalSince1970: 1_909_999_000),
            repeatRule: .daily,
            category: .work,
            priority: .low,
            status: .cancelled,
            color: .red,
            createdAt: original.createdAt,
            updatedAt: Date(timeIntervalSince1970: 1_920_000_000)
        )

        EventEntityMapper.apply(updated, to: entity)
        let restored = EventEntityMapper.makeDomain(from: entity)

        XCTAssertEqual(restored.title, "After")
        XCTAssertEqual(restored.description, "Changed")
        XCTAssertEqual(restored.date, updated.date)
        XCTAssertEqual(restored.endDate, updated.endDate)
        XCTAssertEqual(restored.timeZoneIdentifier, "UTC")
        XCTAssertEqual(restored.reminder, updated.reminder)
        XCTAssertEqual(restored.repeatRule, .daily)
        XCTAssertEqual(restored.category, .work)
        XCTAssertEqual(restored.priority, .low)
        XCTAssertEqual(restored.status, .cancelled)
        XCTAssertEqual(restored.color, .red)
        XCTAssertEqual(restored.createdAt, original.createdAt)
        XCTAssertEqual(restored.updatedAt, updated.updatedAt)
    }

    func testNilTimeZoneFallsBackToCurrent() {
        let entity = EventEntity(
            id: UUID(),
            title: "Legacy",
            eventDescription: "",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            endDate: nil,
            timeZoneIdentifier: nil,
            reminder: nil,
            repeatRuleRawValue: "none",
            categoryRawValue: "work",
            priorityRawValue: "medium",
            statusRawValue: "pending",
            colorRawValue: "green",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )

        let domain = EventEntityMapper.makeDomain(from: entity)
        XCTAssertNil(domain.endDate)
        XCTAssertEqual(domain.timeZoneIdentifier, TimeZone.current.identifier)
    }

    // MARK: - Unknown Raw Values

    func testUnknownEnumRawValuesFallBackToDefaults() {
        let entity = EventEntity(
            id: UUID(),
            title: "Fallback",
            eventDescription: "",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            reminder: nil,
            repeatRuleRawValue: "none",
            categoryRawValue: "not-a-category",
            priorityRawValue: "not-a-priority",
            statusRawValue: "not-a-status",
            colorRawValue: "not-a-color",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )

        let domain = EventEntityMapper.makeDomain(from: entity)

        XCTAssertEqual(domain.category, .other)
        XCTAssertEqual(domain.priority, .medium)
        XCTAssertEqual(domain.status, .pending)
        XCTAssertEqual(domain.color, .green)
    }
}

//
//  RecurrenceEngineTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for ``RecurrenceEngine`` expansion (no physical copies).
final class RecurrenceEngineTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var engine: RecurrenceEngine!

    override func setUp() {
        super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
        engine = RecurrenceEngine(calendar: calendar)
    }

    // MARK: - Daily

    func testDailyOccurrencesInWeek() {
        let master = Event(
            title: "Standup",
            date: date(2026, 7, 13, hour: 9),
            endDate: date(2026, 7, 13, hour: 9, minute: 30),
            timeZoneIdentifier: "UTC",
            repeatRule: .daily
        )
        let interval = DateInterval(start: date(2026, 7, 13), end: date(2026, 7, 20))
        let occurrences = engine.occurrences(of: master, in: interval)

        XCTAssertEqual(occurrences.count, 7)
        XCTAssertEqual(occurrences.map(\.occurrenceIndex), Array(1...7))
        XCTAssertEqual(occurrences.first?.occurrenceStart, date(2026, 7, 13, hour: 9))
        XCTAssertEqual(occurrences.last?.occurrenceStart, date(2026, 7, 19, hour: 9))
        // Same master id — no physical copies.
        XCTAssertTrue(occurrences.allSatisfy { $0.master.id == master.id })
    }

    // MARK: - Weekly / Biweekly

    func testWeeklyOccurrences() {
        let master = Event(
            title: "Sync",
            date: date(2026, 7, 1, hour: 10),
            endDate: date(2026, 7, 1, hour: 11),
            timeZoneIdentifier: "UTC",
            repeatRule: .weekly
        )
        let interval = DateInterval(start: date(2026, 7, 1), end: date(2026, 7, 29))
        let starts = engine.occurrences(of: master, in: interval).map(\.occurrenceStart)
        XCTAssertEqual(
            starts,
            [
                date(2026, 7, 1, hour: 10),
                date(2026, 7, 8, hour: 10),
                date(2026, 7, 15, hour: 10),
                date(2026, 7, 22, hour: 10)
            ]
        )
    }

    func testBiweeklyOccurrences() {
        let master = Event(
            title: "Fortnight",
            date: date(2026, 7, 1, hour: 12),
            timeZoneIdentifier: "UTC",
            repeatRule: .biweekly
        )
        let interval = DateInterval(start: date(2026, 7, 1), end: date(2026, 8, 1))
        let starts = engine.occurrences(of: master, in: interval).map(\.occurrenceStart)
        XCTAssertEqual(
            starts,
            [
                date(2026, 7, 1, hour: 12),
                date(2026, 7, 15, hour: 12),
                date(2026, 7, 29, hour: 12)
            ]
        )
    }

    // MARK: - Monthly / Yearly

    func testMonthlyOccurrencesAcrossMonths() {
        let master = Event(
            title: "Rent",
            date: date(2026, 1, 31, hour: 8),
            timeZoneIdentifier: "UTC",
            repeatRule: .monthly
        )
        let interval = DateInterval(start: date(2026, 1, 1), end: date(2026, 5, 1))
        let days = engine.occurrences(of: master, in: interval).map {
            calendar.component(.day, from: $0.occurrenceStart)
        }
        // Jan 31, Feb 28 (clamped by Calendar), Mar 31, Apr 30
        XCTAssertEqual(days.count, 4)
        XCTAssertEqual(days[0], 31)
        XCTAssertEqual(days[1], 28)
    }

    func testYearlyOccurrences() {
        let master = Event(
            title: "Anniversary",
            date: date(2024, 2, 29, hour: 18),
            timeZoneIdentifier: "UTC",
            repeatRule: .yearly
        )
        let interval = DateInterval(start: date(2024, 1, 1), end: date(2028, 1, 1))
        let years = engine.occurrences(of: master, in: interval).map {
            calendar.component(.year, from: $0.occurrenceStart)
        }
        XCTAssertEqual(years, [2024, 2025, 2026, 2027])
    }

    // MARK: - End Rules

    func testEndsAfterOccurrenceCount() {
        let master = Event(
            title: "Limited",
            date: date(2026, 7, 1, hour: 9),
            timeZoneIdentifier: "UTC",
            repeatRule: RepeatRule(frequency: .daily, occurrenceCount: 3)
        )
        let interval = DateInterval(start: date(2026, 7, 1), end: date(2026, 8, 1))
        let occurrences = engine.occurrences(of: master, in: interval)
        XCTAssertEqual(occurrences.count, 3)
        XCTAssertEqual(occurrences.map(\.occurrenceIndex), [1, 2, 3])
    }

    func testEndsOnDateInclusive() {
        let master = Event(
            title: "Until",
            date: date(2026, 7, 1, hour: 9),
            timeZoneIdentifier: "UTC",
            repeatRule: RepeatRule(
                frequency: .daily,
                endDate: date(2026, 7, 3)
            )
        )
        let interval = DateInterval(start: date(2026, 7, 1), end: date(2026, 7, 10))
        let starts = engine.occurrences(of: master, in: interval).map {
            calendar.startOfDay(for: $0.occurrenceStart)
        }
        XCTAssertEqual(
            starts,
            [date(2026, 7, 1), date(2026, 7, 2), date(2026, 7, 3)]
        )
    }

    // MARK: - Multi-day + Recurrence

    func testMultiDayRecurringAppearsOnSpanDays() {
        let master = Event(
            title: "Retreat",
            date: date(2026, 7, 1),
            endDate: date(2026, 7, 3, hour: 23, minute: 59, second: 59),
            isAllDay: true,
            timeZoneIdentifier: "UTC",
            repeatRule: .weekly
        )

        XCTAssertTrue(engine.occurs(master, on: date(2026, 7, 2)))
        XCTAssertTrue(engine.occurs(master, on: date(2026, 7, 8)))
        XCTAssertTrue(engine.occurs(master, on: date(2026, 7, 10)))
        XCTAssertFalse(engine.occurs(master, on: date(2026, 7, 4)))
    }

    func testCatalogExpandsRecurrenceForDayList() async throws {
        let master = Event(
            title: "Yoga",
            date: date(2026, 7, 6, hour: 7),
            endDate: date(2026, 7, 6, hour: 8),
            timeZoneIdentifier: "UTC",
            repeatRule: .weekly
        )
        let catalog = EventCatalogService(calendar: calendar)
        catalog.replaceAll(with: [master])

        let monday = catalog.events(on: date(2026, 7, 6))
        let nextMonday = catalog.events(on: date(2026, 7, 13))
        let tuesday = catalog.events(on: date(2026, 7, 7))

        XCTAssertEqual(monday.map(\.title), ["Yoga"])
        XCTAssertEqual(nextMonday.map(\.title), ["Yoga"])
        XCTAssertTrue(tuesday.isEmpty)
        XCTAssertEqual(monday.first?.date, date(2026, 7, 6, hour: 7))
        XCTAssertEqual(nextMonday.first?.date, date(2026, 7, 13, hour: 7))
    }

    func testRecurrenceEngineOccurrencesForDailySeries() {
        let master = Event(
            title: "Engine",
            date: date(2026, 7, 1, hour: 9),
            timeZoneIdentifier: "UTC",
            repeatRule: .daily
        )
        let interval = DateInterval(start: date(2026, 7, 1), end: date(2026, 7, 4))
        XCTAssertEqual(engine.occurrences(of: master, in: interval).count, 3)
    }

    func testRepeatRuleRoundTripOccurrenceCount() throws {
        let original = RepeatRule(frequency: .weekly, occurrenceCount: 5)
        let decoded = try RepeatRule.decodeFromPersistence(try original.encodeForPersistence())
        XCTAssertEqual(decoded.frequency, .weekly)
        XCTAssertEqual(decoded.occurrenceCount, 5)
        XCTAssertEqual(decoded.asRecurrenceRule.end, .after(count: 5))
    }

    // MARK: - Helpers

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.date(from: components)!
    }
}

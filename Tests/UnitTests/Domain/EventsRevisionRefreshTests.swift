//
//  EventsRevisionRefreshTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for event-revision sync helpers.
final class EventsRevisionRefreshTests: XCTestCase {

    // MARK: - Day Refresh Identity

    func testTokenChangesWhenEventCountChanges() {
        let base = CalendarDay(
            id: "2026-7-29-currentMonth",
            date: Date(timeIntervalSince1970: 0),
            dayNumber: 29,
            membership: .currentMonth,
            isToday: false,
            eventCount: 0,
            eventColors: []
        )
        let withEvents = base.applyingEvents([
            Event(title: "A", date: base.date, color: .green)
        ])

        XCTAssertNotEqual(
            CalendarDayRefreshIdentity.token(for: base),
            CalendarDayRefreshIdentity.token(for: withEvents)
        )
    }

    func testTokenChangesWhenColorsChange() {
        let dayGreen = CalendarDay(
            id: "day",
            date: Date(timeIntervalSince1970: 0),
            dayNumber: 1,
            membership: .currentMonth,
            isToday: false,
            eventCount: 1,
            eventColors: [.green]
        )
        var dayYellow = dayGreen
        dayYellow.eventColors = [.yellow]

        XCTAssertNotEqual(
            CalendarDayRefreshIdentity.token(for: dayGreen),
            CalendarDayRefreshIdentity.token(for: dayYellow)
        )
    }
}

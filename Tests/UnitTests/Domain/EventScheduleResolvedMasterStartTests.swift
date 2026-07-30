//
//  EventScheduleResolvedMasterStartTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// PB-05.2 — schedule math extracted from ``EventPersistenceService``.
final class EventScheduleResolvedMasterStartTests: XCTestCase {

    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        calendar = cal
    }

    func testSameDayMasterKeepsTargetWhenPresentedIsMaster() {
        let master = Event(
            title: "Standup",
            date: date(2026, 7, 6, hour: 9),
            timeZoneIdentifier: "UTC"
        )
        let target = date(2026, 7, 8, hour: 11)
        let resolved = EventSchedule.resolvedMasterStart(
            master: master,
            presented: master,
            targetStart: target,
            calendar: calendar
        )
        XCTAssertEqual(resolved, target)
    }

    func testOccurrenceDayShiftMovesMasterByDeltaKeepingWallClock() {
        let master = Event(
            title: "Weekly",
            date: date(2026, 7, 6, hour: 9),
            timeZoneIdentifier: "UTC",
            repeatRule: .weekly
        )
        // Virtual occurrence one week later (same wall-clock).
        let presented = Event(
            id: master.id,
            title: master.title,
            date: date(2026, 7, 13, hour: 9),
            timeZoneIdentifier: "UTC",
            repeatRule: .weekly
        )
        // User picks the following Monday for that occurrence → series +7 days from master.
        let target = date(2026, 7, 20, hour: 9)
        let resolved = EventSchedule.resolvedMasterStart(
            master: master,
            presented: presented,
            targetStart: target,
            calendar: calendar
        )
        XCTAssertEqual(resolved, date(2026, 7, 13, hour: 9))
    }

    func testAllDayOccurrenceUsesNormalizedStartOfDay() {
        let masterStart = date(2026, 7, 6, hour: 0)
        let master = Event(
            title: "Holiday",
            date: masterStart,
            endDate: date(2026, 7, 6, hour: 23, minute: 59, second: 59),
            isAllDay: true,
            timeZoneIdentifier: "UTC"
        )
        let presented = Event(
            id: master.id,
            title: master.title,
            date: date(2026, 7, 7, hour: 12),
            endDate: date(2026, 7, 7, hour: 23, minute: 59, second: 59),
            isAllDay: true,
            timeZoneIdentifier: "UTC"
        )
        let target = date(2026, 7, 10, hour: 15)
        let resolved = EventSchedule.resolvedMasterStart(
            master: master,
            presented: presented,
            targetStart: target,
            calendar: calendar
        )
        let expected = EventSchedule.start(
            onDay: date(2026, 7, 9, hour: 0),
            timeFrom: master.date,
            isAllDay: true,
            timeZoneIdentifier: "UTC"
        )
        XCTAssertEqual(resolved, expected)
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

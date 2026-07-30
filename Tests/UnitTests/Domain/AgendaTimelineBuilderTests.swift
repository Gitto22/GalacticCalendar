//
//  AgendaTimelineBuilderTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for Sprint 6.8 Smart Daily Agenda timeline / free-time builder.
@MainActor
final class AgendaTimelineBuilderTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private let day = Date(timeIntervalSince1970: 1_900_051_200) // fixed UTC morning-ish

    override func setUp() async throws {
        try await super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal
    }

    private func date(hour: Int, minute: Int = 0) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start)!
    }

    private func timed(
        title: String,
        startHour: Int,
        startMinute: Int = 0,
        endHour: Int,
        endMinute: Int = 0,
        color: EventColor = .green,
        priority: EventPriority = .normal,
        tags: [EventTag] = [.preset(.work)]
    ) -> Event {
        Event(
            title: title,
            date: date(hour: startHour, minute: startMinute),
            endDate: date(hour: endHour, minute: endMinute),
            isAllDay: false,
            timeZoneIdentifier: "UTC",
            tags: tags,
            priority: priority,
            color: color
        )
    }

    private func allDay(_ title: String) -> Event {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start)!
        return Event(
            title: title,
            date: start,
            endDate: end,
            isAllDay: true,
            timeZoneIdentifier: "UTC",
            color: .yellow
        )
    }

    // MARK: - Timeline / sorting

    func testTimelineOrdersEventsAndFreeBlocksChronologically() {
        let events = [
            timed(title: "Dentist", startHour: 11, endHour: 12),
            timed(title: "Standup", startHour: 9, endHour: 9, endMinute: 30)
        ]
        let snapshot = AgendaTimelineBuilder.build(
            events: events,
            day: day,
            now: date(hour: 8),
            calendar: calendar
        )

        let titles = snapshot.timeline.compactMap { item -> String? in
            if case .event(let event) = item { return event.title }
            return nil
        }
        XCTAssertEqual(titles, ["Standup", "Dentist"])

        // Free block between 09:30 and 11:00
        let free = snapshot.freeBlocks.first {
            calendar.component(.hour, from: $0.start) == 9
                && calendar.component(.minute, from: $0.start) == 30
        }
        XCTAssertNotNil(free)
        XCTAssertEqual(calendar.component(.hour, from: free!.end), 11)
    }

    func testTimedEventsSortedByStart() {
        let events = [
            timed(title: "B", startHour: 14, endHour: 15),
            timed(title: "A", startHour: 10, endHour: 11)
        ]
        let snapshot = AgendaTimelineBuilder.build(
            events: events,
            day: day,
            now: date(hour: 8),
            calendar: calendar
        )
        XCTAssertEqual(snapshot.timedEvents.map(\.title), ["A", "B"])
    }

    // MARK: - Free time

    func testFreeTimeDetectsGapBetweenMeetings() {
        let events = [
            timed(title: "Meeting", startHour: 9, endHour: 9, endMinute: 45),
            timed(title: "Dentist", startHour: 11, endHour: 12)
        ]
        let snapshot = AgendaTimelineBuilder.build(
            events: events,
            day: day,
            now: date(hour: 8),
            calendar: calendar
        )

        let gap = snapshot.freeBlocks.first {
            calendar.component(.hour, from: $0.start) == 9
                && calendar.component(.minute, from: $0.start) == 45
                && calendar.component(.hour, from: $0.end) == 11
        }
        XCTAssertNotNil(gap)
        XCTAssertEqual(gap!.duration, 75 * 60, accuracy: 1)
    }

    func testOverlappingEventsMergeOccupiedTime() {
        let events = [
            timed(title: "A", startHour: 10, endHour: 12),
            timed(title: "B", startHour: 11, endHour: 13)
        ]
        let snapshot = AgendaTimelineBuilder.build(
            events: events,
            day: day,
            now: date(hour: 8),
            calendar: calendar
        )
        // Merged 10:00–13:00 = 3h
        XCTAssertEqual(snapshot.summary.occupiedSeconds, 3 * 3_600, accuracy: 1)
    }

    // MARK: - All day

    func testAllDayEventsExcludedFromTimelineBusyGeometry() {
        let events = [
            allDay("Holiday"),
            timed(title: "Call", startHour: 10, endHour: 11)
        ]
        let snapshot = AgendaTimelineBuilder.build(
            events: events,
            day: day,
            now: date(hour: 8),
            calendar: calendar
        )

        XCTAssertEqual(snapshot.allDayEvents.map(\.title), ["Holiday"])
        XCTAssertEqual(snapshot.timedEvents.map(\.title), ["Call"])
        XCTAssertEqual(snapshot.summary.allDayCount, 1)
        XCTAssertEqual(snapshot.summary.timedCount, 1)
        XCTAssertEqual(snapshot.summary.eventCount, 2)
        // Only 1h occupied from the call inside 08–20 window
        XCTAssertEqual(snapshot.summary.occupiedSeconds, 3_600, accuracy: 1)
        XCTAssertFalse(snapshot.timeline.contains {
            if case .event(let event) = $0 { return event.isAllDay }
            return false
        })
    }

    // MARK: - Next event

    func testNextEventIsFirstAfterNowOnToday() {
        let events = [
            timed(title: "Past", startHour: 8, endHour: 9),
            timed(title: "Soon", startHour: 11, endHour: 12),
            timed(title: "Later", startHour: 15, endHour: 16)
        ]
        let snapshot = AgendaTimelineBuilder.build(
            events: events,
            day: day,
            now: date(hour: 10),
            calendar: calendar
        )
        XCTAssertEqual(snapshot.nextEvent?.title, "Soon")
    }

    func testNextEventNilWhenNoUpcomingToday() {
        let events = [timed(title: "Done", startHour: 8, endHour: 9)]
        let snapshot = AgendaTimelineBuilder.build(
            events: events,
            day: day,
            now: date(hour: 18),
            calendar: calendar
        )
        XCTAssertNil(snapshot.nextEvent)
    }

    // MARK: - Empty day

    func testEmptyDayHasFullFreeWindowAndNoTimelineEvents() {
        let snapshot = AgendaTimelineBuilder.build(
            events: [],
            day: day,
            now: date(hour: 10),
            calendar: calendar
        )
        XCTAssertEqual(snapshot.summary.eventCount, 0)
        XCTAssertTrue(snapshot.timeline.filter {
            if case .event = $0 { return true }
            return false
        }.isEmpty)
        XCTAssertEqual(snapshot.summary.occupiedSeconds, 0, accuracy: 0.1)
        XCTAssertEqual(
            snapshot.summary.freeSeconds,
            AgendaTimelineBuilder.WorkingHours.default.durationSeconds,
            accuracy: 1
        )
        XCTAssertNil(snapshot.nextEvent)
        XCTAssertEqual(snapshot.freeBlocks.count, 1)
    }

    // MARK: - ViewModel integration

    func testSmartAgendaViewModelObservesCatalog() async throws {
        let standup = timed(title: "Standup", startHour: 9, endHour: 10)
        let persistence = EventPersistenceService(
            repository: InMemoryEventRepository(seed: [standup])
        )
        try await persistence.refresh()

        let viewModel = SmartAgendaViewModel(
            day: day,
            persistenceService: persistence,
            calendar: calendar,
            now: { self.date(hour: 8) }
        )

        XCTAssertEqual(viewModel.summary.eventCount, 1)
        XCTAssertEqual(viewModel.nextEvent?.title, "Standup")
        XCTAssertFalse(viewModel.isEmptyDay)
    }
}

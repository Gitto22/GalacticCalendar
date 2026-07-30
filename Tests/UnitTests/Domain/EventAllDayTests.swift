//
//  EventAllDayTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for Sprint 6.1 all-day events (create, edit, persistence, display).
@MainActor
final class EventAllDayTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var timeZone: TimeZone!

    override func setUp() async throws {
        try await super.setUp()
        timeZone = TimeZone(secondsFromGMT: 0)!
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        calendar = gregorian
    }

    // MARK: - Schedule Normalization

    func testNormalizeSameDayAllDayUsesDayBounds() {
        let midday = date(2026, 7, 15, hour: 14)
        let bounds = EventSchedule.normalizeSameDayAllDay(
            date: midday,
            timeZoneIdentifier: "UTC"
        )

        XCTAssertEqual(bounds.date, date(2026, 7, 15, hour: 0))
        XCTAssertEqual(bounds.endDate, date(2026, 7, 15, hour: 23, minute: 59, second: 59))
        XCTAssertFalse(
            EventSchedule.spansMultipleCalendarDays(
                date: bounds.date,
                endDate: bounds.endDate,
                timeZoneIdentifier: "UTC"
            )
        )
    }

    func testSpansMultipleCalendarDaysDetectsCrossDayEnd() {
        XCTAssertTrue(
            EventSchedule.spansMultipleCalendarDays(
                date: date(2026, 7, 15),
                endDate: date(2026, 7, 16),
                timeZoneIdentifier: "UTC"
            )
        )
    }

    func testDisplaySortPlacesAllDayBeforeTimed() {
        let timed = Event(
            title: "A Timed",
            date: date(2026, 7, 15, hour: 9),
            isAllDay: false,
            timeZoneIdentifier: "UTC"
        )
        let allDay = Event(
            title: "Z All Day",
            date: date(2026, 7, 15),
            isAllDay: true,
            timeZoneIdentifier: "UTC"
        )
        let sorted = [timed, allDay].sorted(by: EventSchedule.displaySort)
        XCTAssertEqual(sorted.map(\.title), ["Z All Day", "A Timed"])
    }

    // MARK: - Creation

    func testCreateAllDayEventPersistsNormalizedBounds() async throws {
        let persistence = EventPersistenceService(
            repository: InMemoryEventRepository(),
            catalog: EventCatalogService(calendar: calendar)
        )
        try await persistence.refresh()

        let viewModel = EventEditorViewModel(
            persistenceService: persistence,
            initialDate: date(2026, 7, 15, hour: 14)
        )
        viewModel.timeZoneIdentifier = "UTC"
        viewModel.title = "Holiday"
        viewModel.reminderOption = .none
        viewModel.isAllDay = true

        await viewModel.createEvent()

        XCTAssertTrue(viewModel.didCompleteMutation)
        let stored = try XCTUnwrap(persistence.events.first)
        XCTAssertTrue(stored.isAllDay)
        XCTAssertEqual(stored.date, date(2026, 7, 15, hour: 0))
        XCTAssertEqual(stored.endDate, date(2026, 7, 15, hour: 23, minute: 59, second: 59))
    }

    // MARK: - Editing

    func testEditTimedToAllDayUpdatesFlag() async throws {
        let existing = Event(
            title: "Meeting",
            date: date(2026, 7, 15, hour: 10),
            endDate: date(2026, 7, 15, hour: 11),
            isAllDay: false,
            timeZoneIdentifier: "UTC",
            reminder: nil
        )
        let persistence = EventPersistenceService(
            repository: InMemoryEventRepository(seed: [existing]),
            catalog: EventCatalogService(calendar: calendar)
        )
        try await persistence.refresh()

        let viewModel = EventEditorViewModel(
            persistenceService: persistence,
            event: existing
        )
        viewModel.isAllDay = true
        viewModel.reminderOption = .none

        await viewModel.updateEvent()

        let updated = try XCTUnwrap(persistence.event(id: existing.id))
        XCTAssertTrue(updated.isAllDay)
        XCTAssertEqual(updated.date, date(2026, 7, 15, hour: 0))
    }

    func testToggleAllDayOffRestoresCachedTimedRange() {
        let viewModel = EventEditorViewModel(
            persistenceService: EventPersistenceService(repository: InMemoryEventRepository()),
            initialDate: date(2026, 7, 15, hour: 10)
        )
        viewModel.timeZoneIdentifier = "UTC"
        viewModel.endDate = date(2026, 7, 15, hour: 12)

        viewModel.isAllDay = true
        XCTAssertEqual(viewModel.date, date(2026, 7, 15, hour: 0))

        viewModel.isAllDay = false
        XCTAssertEqual(viewModel.date, date(2026, 7, 15, hour: 10))
        XCTAssertEqual(viewModel.endDate, date(2026, 7, 15, hour: 12))
    }

    func testPrepareForEditingLoadsAllDayFlag() {
        let event = Event(
            title: "Offsite",
            date: date(2026, 7, 15),
            endDate: date(2026, 7, 15, hour: 23, minute: 59, second: 59),
            isAllDay: true,
            timeZoneIdentifier: "UTC"
        )
        let viewModel = EventEditorViewModel(
            persistenceService: EventPersistenceService(repository: InMemoryEventRepository(seed: [event])),
            event: event
        )
        XCTAssertTrue(viewModel.isAllDay)
        XCTAssertEqual(viewModel.date, date(2026, 7, 15, hour: 0))
    }

    // MARK: - Persistence / Mapper

    func testMapperPersistsIsAllDay() {
        let event = Event(
            title: "Conference",
            date: date(2026, 7, 15),
            endDate: date(2026, 7, 15, hour: 23, minute: 59, second: 59),
            isAllDay: true,
            timeZoneIdentifier: "UTC"
        )
        let entity = EventEntityMapper.makeEntity(from: event)
        XCTAssertTrue(entity.isAllDay)
        XCTAssertTrue(EventEntityMapper.makeDomain(from: entity).isAllDay)
    }

    func testDuplicateCopiesIsAllDay() {
        let source = Event(
            title: "Festival",
            date: date(2026, 7, 15),
            isAllDay: true,
            timeZoneIdentifier: "UTC"
        )
        XCTAssertTrue(source.duplicated().isAllDay)
    }

    // MARK: - Display / Day List

    func testDayEventsViewModelSplitsAllDayAndTimed() async throws {
        let day = date(2026, 7, 15)
        let allDay = Event(
            title: "All day",
            date: day,
            isAllDay: true,
            timeZoneIdentifier: "UTC"
        )
        let morning = Event(
            title: "Morning",
            date: date(2026, 7, 15, hour: 9),
            isAllDay: false,
            timeZoneIdentifier: "UTC"
        )
        let afternoon = Event(
            title: "Afternoon",
            date: date(2026, 7, 15, hour: 15),
            isAllDay: false,
            timeZoneIdentifier: "UTC"
        )
        let persistence = EventPersistenceService(
            repository: InMemoryEventRepository(seed: [afternoon, allDay, morning]),
            catalog: EventCatalogService(calendar: calendar)
        )
        try await persistence.refresh()

        let dayVM = DayEventsViewModel(date: day, persistenceService: persistence)

        XCTAssertEqual(dayVM.events.map(\.title), ["All day", "Morning", "Afternoon"])
        XCTAssertEqual(dayVM.allDayEvents.map(\.title), ["All day"])
        XCTAssertEqual(dayVM.timedEvents.map(\.title), ["Morning", "Afternoon"])
    }

    func testCatalogDayQueryKeepsIndicatorsCompatible() async throws {
        let day = date(2026, 7, 15)
        let allDay = Event(
            title: "Holiday",
            date: day,
            isAllDay: true,
            timeZoneIdentifier: "UTC",
            color: .orange
        )
        let catalog = EventCatalogService(calendar: calendar)
        catalog.replaceAll(with: [allDay])

        let grouped = catalog.eventsGroupedByDay(
            in: DateInterval(start: day, duration: 86_400)
        )
        XCTAssertEqual(grouped[day]?.count, 1)
        XCTAssertEqual(grouped[day]?.first?.color, .orange)
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

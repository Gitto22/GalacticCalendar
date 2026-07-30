//
//  EventMultiDayTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for Sprint 6.2 multi-day events.
@MainActor
final class EventMultiDayTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var engine: CalendarEngine!

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
        engine = CalendarEngine(calendar: calendar, today: date(2026, 7, 15))
    }

    // MARK: - Single Day

    func testSingleDayEventIsNotMultiDay() {
        let event = Event(
            title: "Single",
            date: date(2026, 7, 15, hour: 10),
            endDate: date(2026, 7, 15, hour: 11),
            timeZoneIdentifier: "UTC"
        )
        XCTAssertFalse(event.isMultiDay)
        XCTAssertEqual(event.startDate, event.date)
        XCTAssertTrue(event.occurs(on: date(2026, 7, 15), calendar: calendar))
        XCTAssertFalse(event.occurs(on: date(2026, 7, 16), calendar: calendar))
    }

    func testSingleDayAllDayStillWorks() {
        let bounds = EventSchedule.normalizeSameDayAllDay(
            date: date(2026, 7, 15, hour: 14),
            timeZoneIdentifier: "UTC"
        )
        let event = Event(
            title: "Holiday",
            date: bounds.date,
            endDate: bounds.endDate,
            isAllDay: true,
            timeZoneIdentifier: "UTC"
        )
        XCTAssertFalse(event.isMultiDay)
        XCTAssertTrue(event.occurs(on: date(2026, 7, 15), calendar: calendar))
    }

    // MARK: - Multi Day

    func testMultiDayFlagAndAliases() {
        let event = Event(
            title: "Trip",
            date: date(2026, 7, 15, hour: 9),
            endDate: date(2026, 7, 17, hour: 18),
            timeZoneIdentifier: "UTC"
        )
        XCTAssertTrue(event.isMultiDay)
        XCTAssertTrue(event.spansMultipleCalendarDays)
        XCTAssertEqual(event.startDate, event.date)
    }

    func testOccursOnMiddleAndEdgeDays() {
        let event = Event(
            title: "Conference",
            date: date(2026, 7, 15, hour: 9),
            endDate: date(2026, 7, 17, hour: 18),
            timeZoneIdentifier: "UTC"
        )
        XCTAssertFalse(event.occurs(on: date(2026, 7, 14), calendar: calendar))
        XCTAssertTrue(event.occurs(on: date(2026, 7, 15), calendar: calendar))
        XCTAssertTrue(event.occurs(on: date(2026, 7, 16), calendar: calendar))
        XCTAssertTrue(event.occurs(on: date(2026, 7, 17), calendar: calendar))
        XCTAssertFalse(event.occurs(on: date(2026, 7, 18), calendar: calendar))
    }

    func testAllDayMultiDayNormalization() {
        let bounds = EventSchedule.normalizeAllDay(
            start: date(2026, 7, 15, hour: 14),
            end: date(2026, 7, 17, hour: 8),
            timeZoneIdentifier: "UTC"
        )
        XCTAssertEqual(bounds.date, date(2026, 7, 15))
        XCTAssertEqual(bounds.endDate, date(2026, 7, 17, hour: 23, minute: 59, second: 59))
        XCTAssertTrue(
            EventSchedule.spansMultipleCalendarDays(
                date: bounds.date,
                endDate: bounds.endDate,
                timeZoneIdentifier: "UTC"
            )
        )
    }

    // MARK: - Month / Year Crossing

    func testMonthCrossingDayStarts() {
        let days = engine.dayStarts(
            from: date(2026, 7, 30),
            through: date(2026, 8, 2)
        )
        XCTAssertEqual(
            days,
            [
                date(2026, 7, 30),
                date(2026, 7, 31),
                date(2026, 8, 1),
                date(2026, 8, 2)
            ]
        )
    }

    func testYearCrossingOccurrence() {
        let event = Event(
            title: "NYE",
            date: date(2026, 12, 31, hour: 20),
            endDate: date(2027, 1, 1, hour: 2),
            timeZoneIdentifier: "UTC"
        )
        XCTAssertTrue(event.isMultiDay)
        XCTAssertTrue(event.occurs(on: date(2026, 12, 31), calendar: calendar))
        XCTAssertTrue(event.occurs(on: date(2027, 1, 1), calendar: calendar))
        XCTAssertFalse(event.occurs(on: date(2027, 1, 2), calendar: calendar))
    }

    // MARK: - Catalog / Grid

    func testCatalogEventsOnMiddleDayIncludesMultiDay() async throws {
        let event = Event(
            title: "Festival",
            date: date(2026, 7, 14),
            endDate: date(2026, 7, 16, hour: 23, minute: 59, second: 59),
            isAllDay: true,
            timeZoneIdentifier: "UTC",
            color: .orange
        )
        let catalog = EventCatalogService(calendar: calendar)
        catalog.replaceAll(with: [event])

        XCTAssertEqual(catalog.events(on: date(2026, 7, 14)).map(\.title), ["Festival"])
        XCTAssertEqual(catalog.events(on: date(2026, 7, 15)).map(\.title), ["Festival"])
        XCTAssertEqual(catalog.events(on: date(2026, 7, 16)).map(\.title), ["Festival"])
        XCTAssertTrue(catalog.events(on: date(2026, 7, 17)).isEmpty)
    }

    func testCatalogGroupedByDayPlacesIndicatorsOnEveryDay() {
        let event = Event(
            title: "Camp",
            date: date(2026, 7, 15),
            endDate: date(2026, 7, 17),
            isAllDay: true,
            timeZoneIdentifier: "UTC",
            color: .green
        )
        let catalog = EventCatalogService(calendar: calendar)
        catalog.replaceAll(with: [event])

        let interval = DateInterval(start: date(2026, 7, 1), end: date(2026, 8, 1))
        let grouped = catalog.eventsGroupedByDay(in: interval)

        XCTAssertEqual(grouped[date(2026, 7, 15)]?.count, 1)
        XCTAssertEqual(grouped[date(2026, 7, 16)]?.count, 1)
        XCTAssertEqual(grouped[date(2026, 7, 17)]?.count, 1)
        XCTAssertNil(grouped[date(2026, 7, 18)])
    }

    func testDayEventsViewModelShowsSpanningEvent() async throws {
        let event = Event(
            title: "Travel",
            date: date(2026, 7, 10, hour: 8),
            endDate: date(2026, 7, 20, hour: 20),
            timeZoneIdentifier: "UTC"
        )
        let persistence = EventPersistenceService(
            repository: InMemoryEventRepository(seed: [event]),
            catalog: EventCatalogService(calendar: calendar)
        )
        try await persistence.refresh()

        let dayVM = DayEventsViewModel(
            date: date(2026, 7, 15),
            persistenceService: persistence
        )
        XCTAssertEqual(dayVM.events.map(\.title), ["Travel"])
        XCTAssertTrue(dayVM.timedEvents.contains { $0.id == event.id })
    }

    // MARK: - Validation / Editor

    func testValidationRejectsEndBeforeStart() {
        let service = EventValidationService()
        let event = Event(
            title: "Broken",
            date: date(2026, 7, 15, hour: 12),
            endDate: date(2026, 7, 15, hour: 10),
            timeZoneIdentifier: "UTC"
        )
        XCTAssertTrue(service.validate(event).contains(.invalidEndDate))
    }

    func testEditorClampsEndDateBeforeStart() {
        let viewModel = EventEditorViewModel(
            persistenceService: EventPersistenceService(repository: InMemoryEventRepository()),
            initialDate: date(2026, 7, 15, hour: 10)
        )
        viewModel.timeZoneIdentifier = "UTC"
        viewModel.endDate = date(2026, 7, 17, hour: 18)
        XCTAssertTrue(viewModel.isMultiDay)

        viewModel.endDate = date(2026, 7, 14, hour: 8)
        XCTAssertEqual(viewModel.endDate, viewModel.date)
        XCTAssertFalse(viewModel.isMultiDay)
    }

    func testEditorPersistsMultiDayAllDay() async throws {
        let persistence = EventPersistenceService(
            repository: InMemoryEventRepository(),
            catalog: EventCatalogService(calendar: calendar)
        )
        try await persistence.refresh()

        let viewModel = EventEditorViewModel(
            persistenceService: persistence,
            initialDate: date(2026, 7, 15, hour: 10)
        )
        viewModel.timeZoneIdentifier = "UTC"
        viewModel.title = "Retreat"
        viewModel.reminderOption = .none
        viewModel.isAllDay = true
        viewModel.endDate = date(2026, 7, 18)

        await viewModel.createEvent()

        let stored = try XCTUnwrap(persistence.events.first)
        XCTAssertTrue(stored.isAllDay)
        XCTAssertTrue(stored.isMultiDay)
        XCTAssertEqual(stored.startDate, date(2026, 7, 15))
        XCTAssertEqual(stored.endDate, date(2026, 7, 18, hour: 23, minute: 59, second: 59))
    }

    func testMapperRoundTripKeepsMultiDaySpan() {
        let original = Event(
            title: "Mapped Trip",
            date: date(2026, 12, 30),
            endDate: date(2027, 1, 2, hour: 23, minute: 59, second: 59),
            isAllDay: true,
            timeZoneIdentifier: "UTC"
        )
        let restored = EventEntityMapper.makeDomain(from: EventEntityMapper.makeEntity(from: original))
        XCTAssertEqual(restored, original)
        XCTAssertTrue(restored.isMultiDay)
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

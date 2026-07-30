//
//  HomeViewModelDayRoutingTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Day-tap routing and recurrence master resolve for ``HomeViewModel``.
@MainActor
final class HomeViewModelDayRoutingTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var persistence: EventPersistenceService!
    private let dayAnchor = Date(timeIntervalSince1970: 1_900_000_000) // ~2030-03-17 UTC-ish; use controlled dates

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
        persistence = EventPersistenceService(repository: InMemoryEventRepository())
        try await persistence.refresh()
    }

    // MARK: - selectDay routing

    func testSelectDayWithZeroEventsPresentsCreateEditor() async {
        let home = makeHomeViewModel()
        let day = makeCurrentMonthDay(date(2026, 7, 10))

        await home.selectDay(day)

        XCTAssertTrue(home.isPresentingEventEditor)
        XCTAssertFalse(home.isPresentingDayEvents)
        XCTAssertEqual(home.eventEditorViewModel?.mode, .create)
        XCTAssertEqual(
            calendar.startOfDay(for: home.eventEditorViewModel?.date ?? .distantPast),
            calendar.startOfDay(for: day.date)
        )
    }

    func testSelectDayWithOneEventPresentsEditEditor() async throws {
        let event = Event(
            title: "Solo",
            date: date(2026, 7, 11, hour: 9),
            color: .green
        )
        try await persistence.create(event)
        let home = makeHomeViewModel()

        await home.selectDay(makeCurrentMonthDay(date(2026, 7, 11)))

        XCTAssertTrue(home.isPresentingEventEditor)
        XCTAssertFalse(home.isPresentingDayEvents)
        XCTAssertEqual(home.eventEditorViewModel?.mode, .edit)
        XCTAssertEqual(home.eventEditorViewModel?.editingEventID, event.id)
        XCTAssertEqual(home.eventEditorViewModel?.title, "Solo")
    }

    func testSelectDayWithTwoEventsPresentsDayList() async throws {
        let dayStart = date(2026, 7, 12, hour: 10)
        try await persistence.create(Event(title: "A", date: dayStart, color: .green))
        try await persistence.create(
            Event(title: "B", date: dayStart.addingTimeInterval(3_600), color: .red)
        )
        let home = makeHomeViewModel()

        await home.selectDay(makeCurrentMonthDay(date(2026, 7, 12)))

        XCTAssertTrue(home.isPresentingDayEvents)
        XCTAssertFalse(home.isPresentingEventEditor)
        XCTAssertEqual(home.dayEventsViewModel?.events.count, 2)
    }

    func testSelectOutsideMonthDayIsIgnored() async {
        let home = makeHomeViewModel()
        let outside = CalendarDay(
            id: "outside",
            date: date(2026, 6, 30),
            dayNumber: 30,
            membership: .previousMonth,
            isToday: false,
            eventCount: 0,
            eventColors: []
        )

        await home.selectDay(outside)

        XCTAssertFalse(home.isPresentingEventEditor)
        XCTAssertFalse(home.isPresentingDayEvents)
        XCTAssertNil(home.selectedDate)
    }

    // MARK: - Recurrence master resolve

    func testSelectDaySingleOccurrenceOpensMasterDates() async throws {
        let seriesStart = date(2026, 7, 1, hour: 9)
        let master = Event(
            title: "Daily series",
            date: seriesStart,
            timeZoneIdentifier: "UTC",
            repeatRule: .daily,
            color: .orange
        )
        try await persistence.create(master)

        let occurrenceDay = date(2026, 7, 8)
        let presented = persistence.events(on: occurrenceDay)
        XCTAssertEqual(presented.count, 1)
        XCTAssertEqual(presented[0].id, master.id)
        XCTAssertEqual(
            calendar.startOfDay(for: presented[0].date),
            calendar.startOfDay(for: occurrenceDay)
        )

        let home = makeHomeViewModel()
        await home.selectDay(makeCurrentMonthDay(occurrenceDay))

        XCTAssertTrue(home.isPresentingEventEditor)
        XCTAssertEqual(home.eventEditorViewModel?.editingEventID, master.id)
        XCTAssertEqual(
            calendar.startOfDay(for: home.eventEditorViewModel?.date ?? .distantPast),
            calendar.startOfDay(for: seriesStart),
            "Editor must hydrate master start, not occurrence start"
        )
    }

    // MARK: - Helpers

    private func makeHomeViewModel() -> HomeViewModel {
        let previewRepo = RoutingUniverseRepository()
        let universeEngine = UniverseMessageEngine(repository: previewRepo, calendar: calendar)
        let favoriteService = UniverseMessageService(
            repository: previewRepo,
            engine: universeEngine
        )
        return HomeViewModel(
            eventPersistenceService: persistence,
            universeMessageViewModel: UniverseMessageViewModel(
                engine: universeEngine,
                calendar: calendar,
                now: { self.date(2026, 7, 15) }
            ),
            makeUniverseHistoryViewModel: {
                UniverseHistoryViewModel(
                    repository: previewRepo,
                    favoriteService: favoriteService,
                    calendar: self.calendar
                )
            },
            makeUniverseMessageDetailViewModel: { context in
                UniverseMessageDetailViewModel(
                    context: context,
                    repository: previewRepo,
                    favoriteService: favoriteService,
                    calendar: self.calendar
                )
            }
        )
    }

    private func makeCurrentMonthDay(_ day: Date) -> CalendarDay {
        CalendarDay(
            id: "current-\(day.timeIntervalSince1970)",
            date: calendar.startOfDay(for: day),
            dayNumber: calendar.component(.day, from: day),
            membership: .currentMonth,
            isToday: false,
            eventCount: 0,
            eventColors: []
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}

// MARK: - Test Double

@MainActor
private final class RoutingUniverseRepository: UniverseMessageRepositoryProtocol {

    func fetchAll() async throws -> [UniverseMessage] {
        [UniverseMessage(id: "um", textKey: "universe_message_body", category: .motivation)]
    }

    func fetch(by id: String) async throws -> UniverseMessage? {
        try await fetchAll().first { $0.id == id }
    }

    func ensureSeeded() async throws {}

    func fetchHistory() async throws -> [UniverseMessageHistoryEntry] { [] }

    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws {}

    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage {
        var copy = message
        copy.isFavorite.toggle()
        return copy
    }

    func favoriteMessages() async throws -> [UniverseMessage] { [] }

    func isFavorite(_ message: UniverseMessage) async throws -> Bool { message.isFavorite }
}

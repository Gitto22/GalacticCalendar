//
//  CalendarGoToTodayTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for the “Today” jump on ``CalendarGridViewModel``.
@MainActor
final class CalendarGoToTodayTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var engine: CalendarEngine!
    private var persistence: EventPersistenceService!
    private var calendarAppearance: CalendarAppearanceManager!

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
        engine = CalendarEngine(calendar: calendar, today: date(2026, 7, 15))
        persistence = EventPersistenceService(repository: EmptyTodayEventRepository())
        try await persistence.refresh()
        calendarAppearance = CalendarAppearanceManager(calendar: calendar)
    }

    // MARK: - From Any Month

    func testGoToTodayFromAnotherMonth() {
        let viewModel = makeViewModel()
        viewModel.showMonth(3, year: 2026)
        XCTAssertEqual(viewModel.displayedMonth, 3)

        let didChange = viewModel.goToToday()

        XCTAssertTrue(didChange)
        XCTAssertEqual(viewModel.displayedMonth, 7)
        XCTAssertEqual(viewModel.displayedYear, 2026)
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 15)
        XCTAssertTrue(viewModel.selectedDay?.isToday == true)
        XCTAssertTrue(viewModel.isShowingToday)
    }

    // MARK: - From Any Year

    func testGoToTodayFromAnotherYear() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2030)
        XCTAssertEqual(viewModel.displayedYear, 2030)

        let didChange = viewModel.goToToday()

        XCTAssertTrue(didChange)
        XCTAssertEqual(viewModel.displayedMonth, 7)
        XCTAssertEqual(viewModel.displayedYear, 2026)
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 15)
        XCTAssertTrue(viewModel.isShowingToday)
    }

    // MARK: - Auto-select Today

    func testGoToTodaySelectsCurrentDayWhenAlreadyInCurrentMonth() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.displayedMonth, 7)
        let otherDay = viewModel.presentedDays.first {
            $0.isCurrentMonth && $0.dayNumber == 10
        }
        XCTAssertNotNil(otherDay)
        XCTAssertTrue(viewModel.selectDay(otherDay!))

        let didChange = viewModel.goToToday()

        XCTAssertTrue(didChange)
        XCTAssertEqual(viewModel.displayedMonth, 7)
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 15)
        XCTAssertTrue(viewModel.selectedDay?.isToday == true)
    }

    // MARK: - No Unnecessary Recalculation

    func testGoToTodayIsNoOpWhenAlreadyShowingToday() {
        let viewModel = makeViewModel()
        XCTAssertTrue(viewModel.goToToday())
        XCTAssertTrue(viewModel.isShowingToday)
        let selectedID = viewModel.selectedDayID

        let didChangeAgain = viewModel.goToToday()

        XCTAssertFalse(didChangeAgain)
        XCTAssertEqual(viewModel.selectedDayID, selectedID)
        XCTAssertEqual(viewModel.displayedMonth, 7)
        XCTAssertEqual(viewModel.displayedYear, 2026)
    }

    func testHomeGoToTodaySkipsThemeWorkWhenAlreadyOnToday() {
        let grid = makeViewModel()
        XCTAssertTrue(grid.goToToday())
        calendarAppearance.prepareDisplayedMonth(7, year: 2026)

        let home = makeHomeViewModel()
        home.goToToday(calendarGridViewModel: grid, calendarAppearance: calendarAppearance)

        XCTAssertEqual(calendarAppearance.activeMonthNumber, 7)
        XCTAssertEqual(calendarAppearance.activeYear, 2026)
        XCTAssertTrue(grid.isShowingToday)
    }

    func testHomeGoToTodaySyncsThemeFromRemoteMonth() {
        let grid = makeViewModel()
        grid.showMonth(12, year: 2025)
        calendarAppearance.prepareDisplayedMonth(12, year: 2025)

        let home = makeHomeViewModel()
        home.goToToday(calendarGridViewModel: grid, calendarAppearance: calendarAppearance)

        XCTAssertEqual(grid.displayedMonth, 7)
        XCTAssertEqual(grid.displayedYear, 2026)
        XCTAssertEqual(calendarAppearance.activeMonthNumber, 7)
        XCTAssertEqual(calendarAppearance.activeYear, 2026)
        XCTAssertEqual(home.selectedDate.map { calendar.startOfDay(for: $0) }, date(2026, 7, 15))
    }

    // MARK: - Engine Helpers

    func testEngineCurrentDayHelpers() {
        XCTAssertEqual(engine.currentMonth(), 7)
        XCTAssertEqual(engine.currentYear(), 2026)
        XCTAssertEqual(engine.currentDayOfMonth(), 15)
        XCTAssertTrue(engine.isCurrentPeriod(month: 7, year: 2026))
        XCTAssertFalse(engine.isCurrentPeriod(month: 8, year: 2026))
    }

    // MARK: - Helpers

    private func makeViewModel() -> CalendarGridViewModel {
        CalendarGridViewModel(
            persistenceService: persistence,
            engine: engine,
            calendar: calendar
        )
    }

    private func makeHomeViewModel() -> HomeViewModel {
        let previewRepo = EmptyTodayUniverseRepository()
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

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }
}

// MARK: - Test Doubles

@MainActor
private final class EmptyTodayEventRepository: EventRepositoryProtocol {

    func create(_ event: Event) async throws {}

    func fetchAll() async throws -> [Event] { [] }

    func fetch(by id: UUID) async throws -> Event? { nil }

    func fetch(on date: Date) async throws -> [Event] { [] }

    func fetch(in interval: DateInterval) async throws -> [Event] { [] }

    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] { [:] }

    func update(_ event: Event) async throws {}

    func delete(_ event: Event) async throws {}

    func delete(id: UUID) async throws {}

    func duplicate(_ event: Event) async throws -> Event { event.duplicated() }
}

@MainActor
private final class EmptyTodayUniverseRepository: UniverseMessageRepositoryProtocol {

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

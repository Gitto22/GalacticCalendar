//
//  YearPickerViewModelTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for year picker selection, leap years, and CalendarGrid sync.
@MainActor
final class YearPickerViewModelTests: XCTestCase {

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
        persistence = EventPersistenceService(repository: EmptyYearPickerEventRepository())
        try await persistence.refresh()
        calendarAppearance = CalendarAppearanceManager(calendar: calendar)
    }

    // MARK: - Year Change

    func testSelectYearUpdatesSelectionInsideDefaultRange() {
        let viewModel = YearPickerViewModel(
            selectedYear: 2026,
            month: 7,
            calendar: calendar
        )

        XCTAssertEqual(viewModel.years.first?.year, 2000)
        XCTAssertEqual(viewModel.years.last?.year, 2100)
        XCTAssertEqual(viewModel.years.count, 101)
        XCTAssertTrue(viewModel.selectYear(2030))
        XCTAssertEqual(viewModel.selectedYear, 2030)
        XCTAssertFalse(viewModel.selectYear(1999))
        XCTAssertEqual(viewModel.selectedYear, 2030)
    }

    func testCustomRangeIsEasyToWiden() {
        let range = YearPickerRange(lowerBound: 1990, upperBound: 1995)
        let viewModel = YearPickerViewModel(
            selectedYear: 1992,
            month: 3,
            range: range,
            calendar: calendar
        )

        XCTAssertEqual(viewModel.years.map(\.year), [1990, 1991, 1992, 1993, 1994, 1995])
        XCTAssertEqual(viewModel.selectedYear, 1992)
        XCTAssertTrue(range.contains(1995))
        XCTAssertFalse(range.contains(1989))
    }

    // MARK: - Month Persistence + Grid Sync

    func testApplyYearPickerSelectionKeepsMonthAndUpdatesGrid() {
        let grid = makeGrid()
        grid.showMonth(7, year: 2026)
        let home = makeHomeViewModel()
        home.presentYearPicker(from: grid)

        XCTAssertEqual(home.yearPickerViewModel?.month, 7)
        XCTAssertTrue(home.isPresentingYearPicker)

        home.applyYearPickerSelection(
            2031,
            calendarGridViewModel: grid,
            calendarAppearance: calendarAppearance
        )

        XCTAssertEqual(grid.displayedMonth, 7)
        XCTAssertEqual(grid.displayedYear, 2031)
        XCTAssertFalse(home.isPresentingYearPicker)
        XCTAssertNil(home.yearPickerViewModel)
        XCTAssertEqual(calendarAppearance.activeYear, 2031)
        XCTAssertEqual(calendarAppearance.activeMonthNumber, 7)
    }

    // MARK: - Leap Year

    func testLeapDaySelectionClampsWhenChangingToNonLeapYear() {
        let grid = makeGrid()
        grid.showMonth(2, year: 2024)
        let day29 = grid.presentedDays.first {
            $0.isCurrentMonth && $0.dayNumber == 29
        }
        XCTAssertNotNil(day29)
        XCTAssertTrue(grid.selectDay(day29!))
        XCTAssertTrue(engine.isLeapYear(2024))

        let home = makeHomeViewModel()
        home.presentYearPicker(from: grid)
        home.applyYearPickerSelection(
            2025,
            calendarGridViewModel: grid,
            calendarAppearance: calendarAppearance
        )

        XCTAssertEqual(grid.displayedMonth, 2)
        XCTAssertEqual(grid.displayedYear, 2025)
        XCTAssertFalse(engine.isLeapYear(2025))
        XCTAssertEqual(grid.selectedDay?.dayNumber, 28)
        XCTAssertEqual(engine.numberOfDays(in: 2, year: 2025), 28)
    }

    func testLeapYearFebruaryKeepsDayTwentyNine() {
        let grid = makeGrid()
        grid.showMonth(2, year: 2023)
        let day28 = grid.presentedDays.first {
            $0.isCurrentMonth && $0.dayNumber == 28
        }
        XCTAssertNotNil(day28)
        XCTAssertTrue(grid.selectDay(day28!))

        grid.showMonth(2, year: 2024)

        XCTAssertEqual(grid.displayedMonth, 2)
        XCTAssertEqual(grid.displayedYear, 2024)
        XCTAssertEqual(grid.selectedDay?.dayNumber, 28)
        XCTAssertEqual(engine.numberOfDays(in: 2, year: 2024), 29)
    }

    // MARK: - Helpers

    private func makeGrid() -> CalendarGridViewModel {
        CalendarGridViewModel(
            persistenceService: persistence,
            engine: engine,
            calendar: calendar
        )
    }

    private func makeHomeViewModel() -> HomeViewModel {
        let previewRepo = EmptyYearPickerUniverseRepository()
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
private final class EmptyYearPickerEventRepository: EventRepositoryProtocol {

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
private final class EmptyYearPickerUniverseRepository: UniverseMessageRepositoryProtocol {

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

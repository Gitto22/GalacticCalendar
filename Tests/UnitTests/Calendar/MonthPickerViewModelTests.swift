//
//  MonthPickerViewModelTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for month picker selection and Home synchronization.
@MainActor
final class MonthPickerViewModelTests: XCTestCase {

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
        persistence = EventPersistenceService(repository: EmptyMonthPickerEventRepository())
        try await persistence.refresh()
        calendarAppearance = CalendarAppearanceManager(calendar: calendar)
    }

    // MARK: - Selection

    func testInitializationBuildsTwelveMonthsAndKeepsSelection() {
        let viewModel = MonthPickerViewModel(
            selectedMonth: 7,
            year: 2026,
            calendar: calendar
        )

        XCTAssertEqual(viewModel.months.count, 12)
        XCTAssertEqual(viewModel.months.map(\.month), Array(1...12))
        XCTAssertEqual(viewModel.selectedMonth, 7)
        XCTAssertEqual(viewModel.year, 2026)
        XCTAssertTrue(viewModel.isSelected(7))
        XCTAssertFalse(viewModel.months.contains(where: \.title.isEmpty))
    }

    func testSelectMonthUpdatesSelection() {
        let viewModel = MonthPickerViewModel(
            selectedMonth: 7,
            year: 2026,
            calendar: calendar
        )

        XCTAssertTrue(viewModel.selectMonth(3))
        XCTAssertEqual(viewModel.selectedMonth, 3)
        XCTAssertTrue(viewModel.isSelected(3))
        XCTAssertFalse(viewModel.selectMonth(0))
        XCTAssertEqual(viewModel.selectedMonth, 3)
    }

    // MARK: - Month Change

    func testApplyMonthPickerSelectionChangesGridMonthAndKeepsYear() {
        let grid = CalendarGridViewModel(
            persistenceService: persistence,
            engine: engine,
            calendar: calendar
        )
        let home = makeHomeViewModel()
        home.presentMonthPicker(from: grid)

        XCTAssertEqual(grid.displayedMonth, 7)
        XCTAssertEqual(grid.displayedYear, 2026)
        XCTAssertTrue(home.isPresentingMonthPicker)

        home.applyMonthPickerSelection(
            11,
            calendarGridViewModel: grid,
            calendarAppearance: calendarAppearance
        )

        XCTAssertEqual(grid.displayedMonth, 11)
        XCTAssertEqual(grid.displayedYear, 2026)
        XCTAssertFalse(home.isPresentingMonthPicker)
        XCTAssertNil(home.monthPickerViewModel)
    }

    // MARK: - Home Sync

    func testApplyMonthPickerSelectionSyncsThemeTitleAndBackground() {
        let grid = CalendarGridViewModel(
            persistenceService: persistence,
            engine: engine,
            calendar: calendar
        )
        let home = makeHomeViewModel()
        home.presentMonthPicker(from: grid)

        home.applyMonthPickerSelection(
            2,
            calendarGridViewModel: grid,
            calendarAppearance: calendarAppearance
        )

        XCTAssertEqual(calendarAppearance.activeMonthNumber, 2)
        XCTAssertEqual(calendarAppearance.activeYear, 2026)
        XCTAssertEqual(
            calendarAppearance.activeMonthBackgroundName,
            calendarAppearance.backgroundAssetName(for: 2)
        )
        XCTAssertFalse(calendarAppearance.displayedMonthName().isEmpty)
    }

    // MARK: - Helpers

    private func makeHomeViewModel() -> HomeViewModel {
        let previewRepo = EmptyMonthPickerUniverseRepository()
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
private final class EmptyMonthPickerEventRepository: EventRepositoryProtocol {

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
private final class EmptyMonthPickerUniverseRepository: UniverseMessageRepositoryProtocol {

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

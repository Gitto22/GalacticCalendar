//
//  CalendarSmartDaySelectionTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for smart day selection across months, years, and leap edges.
@MainActor
final class CalendarSmartDaySelectionTests: XCTestCase {

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
        persistence = EventPersistenceService(repository: EmptySmartSelectionEventRepository())
        try await persistence.refresh()
        calendarAppearance = CalendarAppearanceManager(calendar: calendar)
    }

    // MARK: - Engine Algorithm

    func testEngineKeepsDayWhenValid() {
        let result = engine.resolveSelectedDay(preferredDay: 15, month: 3, year: 2026)
        XCTAssertEqual(result?.dayNumber, 15)
        XCTAssertEqual(result?.wasClamped, false)
    }

    func testEngineJanuary31ToFebruaryNonLeap() {
        let result = engine.resolveSelectedDay(preferredDay: 31, month: 2, year: 2025)
        XCTAssertEqual(result?.dayNumber, 28)
        XCTAssertEqual(result?.wasClamped, true)
    }

    func testEngineJanuary31ToFebruaryLeap() {
        let result = engine.resolveSelectedDay(preferredDay: 31, month: 2, year: 2024)
        XCTAssertEqual(result?.dayNumber, 29)
        XCTAssertEqual(result?.wasClamped, true)
    }

    func testEngineApril30ToMayKeeps30() {
        let result = engine.resolveSelectedDay(preferredDay: 30, month: 5, year: 2026)
        XCTAssertEqual(result?.dayNumber, 30)
        XCTAssertEqual(result?.wasClamped, false)
    }

    func testEngineLeapDayCollapsesOnNonLeapYear() {
        XCTAssertTrue(engine.isLeapYear(2028))
        XCTAssertFalse(engine.isLeapYear(2029))
        let result = engine.resolveSelectedDay(preferredDay: 29, month: 2, year: 2029)
        XCTAssertEqual(result?.dayNumber, 28)
        XCTAssertEqual(result?.wasClamped, true)
    }

    func testEngineNilPreferredYieldsNil() {
        XCTAssertNil(engine.resolveSelectedDay(preferredDay: nil, month: 7, year: 2026))
    }

    // MARK: - Month Changes (Grid)

    func testGridJanuary31BecomesFebruary28() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2025)
        select(viewModel, day: 31)

        XCTAssertTrue(viewModel.showMonth(2, year: 2025))
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 28)
        XCTAssertTrue(viewModel.lastSelectionWasClamped)
    }

    func testGridApril30PreservedInMay() {
        let viewModel = makeViewModel()
        viewModel.showMonth(4, year: 2026)
        select(viewModel, day: 30)

        XCTAssertTrue(viewModel.showMonth(5, year: 2026))
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 30)
        XCTAssertFalse(viewModel.lastSelectionWasClamped)
    }

    func testGridPreservesMidMonthAcrossAllMonths() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2026)
        select(viewModel, day: 12)

        for month in 2...12 {
            XCTAssertTrue(viewModel.showMonth(month, year: 2026), "month \(month)")
            XCTAssertEqual(viewModel.selectedDay?.dayNumber, 12, "month \(month)")
            XCTAssertFalse(viewModel.lastSelectionWasClamped, "month \(month)")
        }
    }

    func testGridSamePeriodSkipsRecalculation() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2026)
        select(viewModel, day: 15)
        let idBefore = viewModel.selectedDayID

        XCTAssertFalse(viewModel.showMonth(7, year: 2026))
        XCTAssertEqual(viewModel.selectedDayID, idBefore)
        XCTAssertEqual(viewModel.displayedMonth, 7)
    }

    // MARK: - Year Changes / Leap

    func testLeapDay2028To2029ClampsTo28() {
        let viewModel = makeViewModel()
        viewModel.showMonth(2, year: 2028)
        select(viewModel, day: 29)
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 29)

        XCTAssertTrue(viewModel.showMonth(2, year: 2029))
        XCTAssertEqual(viewModel.displayedMonth, 2)
        XCTAssertEqual(viewModel.displayedYear, 2029)
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 28)
        XCTAssertTrue(viewModel.lastSelectionWasClamped)
    }

    func testYearChangePreservesValidDay() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2026)
        select(viewModel, day: 15)

        XCTAssertTrue(viewModel.showMonth(7, year: 2031))
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 15)
        XCTAssertFalse(viewModel.lastSelectionWasClamped)
    }

    // MARK: - Edge Cases

    func testDay31ThroughShortMonths() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2026)
        select(viewModel, day: 31)

        // Feb (non-leap 2026) → 28
        XCTAssertTrue(viewModel.showMonth(2, year: 2026))
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 28)

        // Mar → 28 preserved
        XCTAssertTrue(viewModel.showMonth(3, year: 2026))
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 28)

        // Apr → 28 preserved
        XCTAssertTrue(viewModel.showMonth(4, year: 2026))
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 28)
    }

    func testNoSelectionStaysNilAfterMonthChange() {
        let viewModel = makeViewModel()
        viewModel.showMonth(3, year: 2026)
        XCTAssertNil(viewModel.selectedDayID)

        XCTAssertTrue(viewModel.showMonth(4, year: 2026))
        XCTAssertNil(viewModel.selectedDayID)
        XCTAssertFalse(viewModel.lastSelectionWasClamped)
    }

    // MARK: - Home Sync / Day Events

    func testHomeSyncUpdatesSelectedDateAndDayEventsPanel() {
        let grid = makeViewModel()
        grid.showMonth(1, year: 2025)
        select(grid, day: 31)

        let home = makeHomeViewModel()
        // Simulate an open day-events panel for the selected January day.
        home.syncDisplayedMonth(from: grid, calendarAppearance: calendarAppearance)
        let panel = DayEventsViewModel(
            date: grid.selectedDay!.date,
            persistenceService: persistence
        )
        // Drive the private refresh path by syncing after clamp with an open panel
        // through Home's public sync (selectedDate) and DayEvents updateDate API.
        XCTAssertTrue(grid.showMonth(2, year: 2025))
        home.syncDisplayedMonth(from: grid, calendarAppearance: calendarAppearance)
        panel.updateDate(home.selectedDate ?? grid.selectedDay!.date)

        XCTAssertEqual(grid.selectedDay?.dayNumber, 28)
        XCTAssertEqual(
            home.selectedDate.map { calendar.startOfDay(for: $0) },
            date(2025, 2, 28)
        )
        XCTAssertEqual(calendar.startOfDay(for: panel.date), date(2025, 2, 28))
    }

    func testDayEventsUpdateDateIsIdempotentForSameDay() {
        let dayVM = DayEventsViewModel(
            date: date(2026, 7, 15),
            persistenceService: persistence
        )
        dayVM.updateDate(date(2026, 7, 15))
        XCTAssertEqual(calendar.startOfDay(for: dayVM.date), date(2026, 7, 15))

        dayVM.updateDate(date(2026, 7, 20))
        XCTAssertEqual(calendar.startOfDay(for: dayVM.date), date(2026, 7, 20))
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
        let previewRepo = EmptySmartSelectionUniverseRepository()
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

    private func select(_ viewModel: CalendarGridViewModel, day: Int) {
        let cell = viewModel.presentedDays.first {
            $0.isCurrentMonth && $0.dayNumber == day
        }
        XCTAssertNotNil(cell)
        XCTAssertTrue(viewModel.selectDay(cell!))
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
private final class EmptySmartSelectionEventRepository: EventRepositoryProtocol {

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
private final class EmptySmartSelectionUniverseRepository: UniverseMessageRepositoryProtocol {

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

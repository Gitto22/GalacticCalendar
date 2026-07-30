//
//  CalendarHardeningTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Edge-case and rapid-navigation hardening for the Calendar Experience epic.
@MainActor
final class CalendarHardeningTests: XCTestCase {

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
        persistence = EventPersistenceService(repository: EmptyHardeningEventRepository())
        try await persistence.refresh()
        calendarAppearance = CalendarAppearanceManager(calendar: calendar)
    }

    // MARK: - Invalid / Inconsistent Inputs

    func testShowMonthRejectsInvalidMonthZero() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2026)
        XCTAssertFalse(viewModel.showMonth(0, year: 2026))
        XCTAssertEqual(viewModel.displayedMonth, 7)
        XCTAssertEqual(viewModel.displayedYear, 2026)
    }

    func testShowMonthRejectsInvalidMonthThirteen() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2026)
        XCTAssertFalse(viewModel.showMonth(13, year: 2026))
        XCTAssertEqual(viewModel.displayedMonth, 7)
    }

    func testSelectOutsideMonthDayReturnsFalse() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2026)
        guard let outside = viewModel.presentedDays.first(where: { $0.isCurrentMonth == false }) else {
            XCTFail("Expected outside-month cell in 42-day grid")
            return
        }
        XCTAssertFalse(viewModel.selectDay(outside))
        XCTAssertNil(viewModel.selectedDayID)
    }

    func testSelectSameDayTwiceIsIdempotent() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2026)
        select(viewModel, day: 15)
        let id = viewModel.selectedDayID
        XCTAssertTrue(viewModel.selectDay(viewModel.selectedDay!))
        XCTAssertEqual(viewModel.selectedDayID, id)
        XCTAssertFalse(viewModel.lastSelectionWasClamped)
    }

    // MARK: - Rapid Consecutive Navigation

    func testRapidConsecutiveNextMonthsStayConsistent() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2026)
        select(viewModel, day: 15)

        for step in 1...24 {
            XCTAssertTrue(
                viewModel.navigateMonth(.next),
                "step \(step) should change period"
            )
            XCTAssertEqual(viewModel.presentedDays.count, CalendarConstants.monthlyGridCellCount)
            XCTAssertEqual(viewModel.selectedDay?.dayNumber, 15)
            XCTAssertFalse(viewModel.lastSelectionWasClamped)
        }

        XCTAssertEqual(viewModel.displayedMonth, 1)
        XCTAssertEqual(viewModel.displayedYear, 2028)
    }

    func testRapidConsecutivePreviousMonthsStayConsistent() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2026)
        select(viewModel, day: 10)

        for _ in 1...12 {
            XCTAssertTrue(viewModel.navigateMonth(.previous))
        }

        XCTAssertEqual(viewModel.displayedMonth, 1)
        XCTAssertEqual(viewModel.displayedYear, 2025)
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 10)
    }

    func testRapidHomeNavigateMonthSyncsThemeOncePerChange() {
        let grid = makeViewModel()
        grid.showMonth(10, year: 2026)
        select(grid, day: 31)
        let home = makeHomeViewModel()
        home.syncDisplayedMonth(from: grid, calendarAppearance: calendarAppearance)

        home.navigateMonth(.next, calendarGridViewModel: grid, calendarAppearance: calendarAppearance)
        XCTAssertEqual(grid.displayedMonth, 11)
        XCTAssertEqual(calendarAppearance.activeMonthNumber, 11)
        XCTAssertEqual(grid.selectedDay?.dayNumber, 30)

        home.navigateMonth(.next, calendarGridViewModel: grid, calendarAppearance: calendarAppearance)
        XCTAssertEqual(grid.displayedMonth, 12)
        XCTAssertEqual(calendarAppearance.activeMonthNumber, 12)
        XCTAssertEqual(grid.selectedDay?.dayNumber, 30)

        home.navigateMonth(.next, calendarGridViewModel: grid, calendarAppearance: calendarAppearance)
        XCTAssertEqual(grid.displayedMonth, 1)
        XCTAssertEqual(grid.displayedYear, 2027)
        XCTAssertEqual(calendarAppearance.activeMonthNumber, 1)
        XCTAssertEqual(calendarAppearance.activeYear, 2027)
        XCTAssertEqual(grid.selectedDay?.dayNumber, 30)
    }

    // MARK: - Day Counts / Boundaries

    func testDecember31PreservedInJanuary() {
        let viewModel = makeViewModel()
        viewModel.showMonth(12, year: 2026)
        select(viewModel, day: 31)

        XCTAssertTrue(viewModel.showMonth(1, year: 2027))
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 31)
        XCTAssertFalse(viewModel.lastSelectionWasClamped)
        XCTAssertEqual(viewModel.displayedYear, 2027)
    }

    func testJanuary31ClampsToApril30() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2026)
        select(viewModel, day: 31)

        XCTAssertTrue(viewModel.showMonth(4, year: 2026))
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 30)
        XCTAssertTrue(viewModel.lastSelectionWasClamped)
    }

    func testDay31ClampsOnThirtyDayMonths() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2026)
        select(viewModel, day: 31)

        for month in [4, 6, 9, 11] {
            XCTAssertTrue(viewModel.showMonth(1, year: 2026))
            select(viewModel, day: 31)
            XCTAssertTrue(viewModel.showMonth(month, year: 2026), "month \(month)")
            XCTAssertEqual(viewModel.selectedDay?.dayNumber, 30, "month \(month)")
            XCTAssertTrue(viewModel.lastSelectionWasClamped, "month \(month)")
        }
    }

    func testFebruary28PreservedAcrossNonLeapYears() {
        let viewModel = makeViewModel()
        viewModel.showMonth(2, year: 2025)
        select(viewModel, day: 28)

        XCTAssertTrue(viewModel.showMonth(2, year: 2026))
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 28)
        XCTAssertFalse(viewModel.lastSelectionWasClamped)
    }

    func testCenturyNonLeapYear1900() {
        XCTAssertFalse(engine.isLeapYear(1900))
        XCTAssertEqual(engine.numberOfDays(in: 2, year: 1900), 28)
        let result = engine.resolveSelectedDay(preferredDay: 29, month: 2, year: 1900)
        XCTAssertEqual(result?.dayNumber, 28)
        XCTAssertEqual(result?.wasClamped, true)
    }

    func testCenturyLeapYear2000() {
        XCTAssertTrue(engine.isLeapYear(2000))
        XCTAssertEqual(engine.numberOfDays(in: 2, year: 2000), 29)
        let result = engine.resolveSelectedDay(preferredDay: 29, month: 2, year: 2000)
        XCTAssertEqual(result?.dayNumber, 29)
        XCTAssertEqual(result?.wasClamped, false)
    }

    // MARK: - Picker Apply No-ops

    func testMonthPickerSameSelectionSkipsThemeSyncButDismisses() {
        let grid = makeViewModel()
        grid.showMonth(7, year: 2026)
        select(grid, day: 15)
        let home = makeHomeViewModel()
        home.syncDisplayedMonth(from: grid, calendarAppearance: calendarAppearance)
        home.presentMonthPicker(from: grid)

        let monthBefore = calendarAppearance.activeMonthNumber
        home.applyMonthPickerSelection(7, calendarGridViewModel: grid, calendarAppearance: calendarAppearance)

        XCTAssertFalse(home.isPresentingMonthPicker)
        XCTAssertNil(home.monthPickerViewModel)
        XCTAssertEqual(grid.displayedMonth, 7)
        XCTAssertEqual(calendarAppearance.activeMonthNumber, monthBefore)
        XCTAssertEqual(grid.selectedDay?.dayNumber, 15)
    }

    func testYearPickerSameSelectionSkipsThemeSyncButDismisses() {
        let grid = makeViewModel()
        grid.showMonth(7, year: 2026)
        select(grid, day: 15)
        let home = makeHomeViewModel()
        home.syncDisplayedMonth(from: grid, calendarAppearance: calendarAppearance)
        home.presentYearPicker(from: grid)

        let yearBefore = calendarAppearance.activeYear
        home.applyYearPickerSelection(2026, calendarGridViewModel: grid, calendarAppearance: calendarAppearance)

        XCTAssertFalse(home.isPresentingYearPicker)
        XCTAssertNil(home.yearPickerViewModel)
        XCTAssertEqual(grid.displayedYear, 2026)
        XCTAssertEqual(calendarAppearance.activeYear, yearBefore)
    }

    func testSyncClearsSelectedDateWhenSelectionNil() {
        let grid = makeViewModel()
        grid.showMonth(7, year: 2026)
        select(grid, day: 15)
        let home = makeHomeViewModel()
        home.syncDisplayedMonth(from: grid, calendarAppearance: calendarAppearance)
        XCTAssertNotNil(home.selectedDate)

        let fresh = makeViewModel()
        fresh.showMonth(8, year: 2026)
        XCTAssertNil(fresh.selectedDayID)
        home.syncDisplayedMonth(from: fresh, calendarAppearance: calendarAppearance)
        XCTAssertNil(home.selectedDate)
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
        let previewRepo = EmptyHardeningUniverseRepository()
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
private final class EmptyHardeningEventRepository: EventRepositoryProtocol {

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
private final class EmptyHardeningUniverseRepository: UniverseMessageRepositoryProtocol {

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

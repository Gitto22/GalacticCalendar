//
//  CalendarMonthSwipeTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for swipe-driven month navigation intents.
@MainActor
final class CalendarMonthSwipeTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var engine: CalendarEngine!
    private var persistence: EventPersistenceService!

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
        engine = CalendarEngine(calendar: calendar, today: date(2026, 7, 15))
        persistence = EventPersistenceService(repository: EmptySwipeEventRepository())
        try await persistence.refresh()
    }

    // MARK: - Swipe Left → Next

    func testSwipeLeftNavigatesToNextMonth() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2026)

        let didChange = viewModel.navigateMonth(.next)

        XCTAssertTrue(didChange)
        XCTAssertEqual(viewModel.displayedMonth, 8)
        XCTAssertEqual(viewModel.displayedYear, 2026)
    }

    // MARK: - Swipe Right → Previous

    func testSwipeRightNavigatesToPreviousMonth() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2026)

        let didChange = viewModel.navigateMonth(.previous)

        XCTAssertTrue(didChange)
        XCTAssertEqual(viewModel.displayedMonth, 6)
        XCTAssertEqual(viewModel.displayedYear, 2026)
    }

    // MARK: - Year Boundaries

    func testSwipeLeftFromDecemberGoesToJanuaryNextYear() {
        let viewModel = makeViewModel()
        viewModel.showMonth(12, year: 2026)

        XCTAssertTrue(viewModel.navigateMonth(.next))
        XCTAssertEqual(viewModel.displayedMonth, 1)
        XCTAssertEqual(viewModel.displayedYear, 2027)

        let engineTarget = engine.period(
            after: .next,
            fromMonth: 12,
            year: 2026
        )
        XCTAssertEqual(engineTarget?.month, 1)
        XCTAssertEqual(engineTarget?.year, 2027)
    }

    func testSwipeRightFromJanuaryGoesToDecemberPreviousYear() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2026)

        XCTAssertTrue(viewModel.navigateMonth(.previous))
        XCTAssertEqual(viewModel.displayedMonth, 12)
        XCTAssertEqual(viewModel.displayedYear, 2025)
    }

    // MARK: - Selection Preservation

    func testSwipePreservesSelectedDayWhenPresentInNextMonth() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2026)
        let day10 = requireCurrentMonthDay(viewModel, dayNumber: 10)
        XCTAssertTrue(viewModel.selectDay(day10))

        XCTAssertTrue(viewModel.navigateMonth(.next))

        XCTAssertEqual(viewModel.displayedMonth, 8)
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 10)
    }

    func testSwipeClampsSelectedDayWhenMissingInShorterMonth() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2026)
        let day31 = requireCurrentMonthDay(viewModel, dayNumber: 31)
        XCTAssertTrue(viewModel.selectDay(day31))

        XCTAssertTrue(viewModel.navigateMonth(.next))

        XCTAssertEqual(viewModel.displayedMonth, 2)
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 28)
    }

    // MARK: - Rapid Multi-Step

    func testRapidMultiStepSwipeJumpsWithoutIntermediateState() {
        let viewModel = makeViewModel()
        viewModel.showMonth(7, year: 2026)

        let intent = CalendarMonthNavigationIntent(direction: .next, stepCount: 3)
        XCTAssertTrue(viewModel.navigateMonth(intent))

        XCTAssertEqual(viewModel.displayedMonth, 10)
        XCTAssertEqual(viewModel.displayedYear, 2026)
    }

    // MARK: - Helpers

    private func makeViewModel() -> CalendarGridViewModel {
        CalendarGridViewModel(
            persistenceService: persistence,
            engine: engine,
            calendar: calendar
        )
    }

    private func requireCurrentMonthDay(
        _ viewModel: CalendarGridViewModel,
        dayNumber: Int
    ) -> CalendarDay {
        let day = viewModel.presentedDays.first {
            $0.isCurrentMonth && $0.dayNumber == dayNumber
        }
        XCTAssertNotNil(day)
        return day!
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
private final class EmptySwipeEventRepository: EventRepositoryProtocol {

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

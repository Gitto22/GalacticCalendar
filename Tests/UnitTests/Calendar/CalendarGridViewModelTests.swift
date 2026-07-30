//
//  CalendarGridViewModelTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for month navigation and selection preservation on the grid.
@MainActor
final class CalendarGridViewModelTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var engine: CalendarEngine!
    private var persistence: EventPersistenceService!

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
        engine = CalendarEngine(
            calendar: calendar,
            today: date(2026, 7, 15)
        )
        persistence = EventPersistenceService(
            repository: EmptyEventRepository()
        )
        try await persistence.refresh()
    }

    // MARK: - Month Change

    func testGoToNextMonthUpdatesDisplayedPeriod() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.displayedMonth, 7)
        XCTAssertEqual(viewModel.displayedYear, 2026)

        viewModel.goToNextMonth()

        XCTAssertEqual(viewModel.displayedMonth, 8)
        XCTAssertEqual(viewModel.displayedYear, 2026)
        XCTAssertEqual(viewModel.presentedDays.count, CalendarConstants.monthlyGridCellCount)
    }

    func testGoToPreviousMonthUpdatesDisplayedPeriod() {
        let viewModel = makeViewModel()

        viewModel.goToPreviousMonth()

        XCTAssertEqual(viewModel.displayedMonth, 6)
        XCTAssertEqual(viewModel.displayedYear, 2026)
    }

    // MARK: - Year Change

    func testDecemberNextMonthRollsToNextYear() {
        let viewModel = makeViewModel()
        viewModel.showMonth(12, year: 2026)

        viewModel.goToNextMonth()

        XCTAssertEqual(viewModel.displayedMonth, 1)
        XCTAssertEqual(viewModel.displayedYear, 2027)
    }

    func testJanuaryPreviousMonthRollsToPreviousYear() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2026)

        viewModel.goToPreviousMonth()

        XCTAssertEqual(viewModel.displayedMonth, 12)
        XCTAssertEqual(viewModel.displayedYear, 2025)
    }

    // MARK: - Different Day Counts / Selection

    func testSelectionPreservedWhenTargetMonthHasSameDay() {
        let viewModel = makeViewModel()
        let day15 = requireCurrentMonthDay(viewModel, dayNumber: 15)
        XCTAssertTrue(viewModel.selectDay(day15))

        viewModel.goToNextMonth()

        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 15)
        XCTAssertEqual(viewModel.displayedMonth, 8)
    }

    func testSelectionClampedWhenDayMissingInShorterMonth() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2026)
        let day31 = requireCurrentMonthDay(viewModel, dayNumber: 31)
        XCTAssertTrue(viewModel.selectDay(day31))

        viewModel.showMonth(2, year: 2026)

        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 28)
        XCTAssertEqual(viewModel.displayedMonth, 2)
    }

    // MARK: - Leap Year

    func testSelectionClampedToLeapDayInFebruary() {
        let viewModel = makeViewModel()
        viewModel.showMonth(1, year: 2024)
        let day31 = requireCurrentMonthDay(viewModel, dayNumber: 31)
        XCTAssertTrue(viewModel.selectDay(day31))

        viewModel.showMonth(2, year: 2024)

        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 29)
        XCTAssertTrue(engine.isLeapYear(2024))
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

// MARK: - Empty Event Repository

@MainActor
private final class EmptyEventRepository: EventRepositoryProtocol {

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

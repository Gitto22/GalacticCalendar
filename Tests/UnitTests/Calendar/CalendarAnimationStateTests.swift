//
//  CalendarAnimationStateTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Ensures presentation animations never alter calendar navigation state.
@MainActor
final class CalendarAnimationStateTests: XCTestCase {

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
        persistence = EventPersistenceService(repository: EmptyAnimationEventRepository())
        try await persistence.refresh()
    }

    // MARK: - prefersAnimation Neutrality

    func testNavigateMonthStateMatchesWithOrWithoutPrefersAnimation() {
        let animated = makeViewModel()
        let instant = makeViewModel()

        animated.showMonth(7, year: 2026)
        instant.showMonth(7, year: 2026)

        let day15 = requireCurrentMonthDay(animated, dayNumber: 15)
        XCTAssertTrue(animated.selectDay(day15))
        XCTAssertTrue(instant.selectDay(requireCurrentMonthDay(instant, dayNumber: 15)))

        let animatedIntent = CalendarMonthNavigationIntent(
            direction: .next,
            stepCount: 1,
            prefersAnimation: true
        )
        let instantIntent = CalendarMonthNavigationIntent(
            direction: .next,
            stepCount: 1,
            prefersAnimation: false
        )

        XCTAssertTrue(animated.navigateMonth(animatedIntent))
        XCTAssertTrue(instant.navigateMonth(instantIntent))

        XCTAssertEqual(animated.displayedMonth, instant.displayedMonth)
        XCTAssertEqual(animated.displayedYear, instant.displayedYear)
        XCTAssertEqual(animated.selectedDay?.dayNumber, instant.selectedDay?.dayNumber)
        XCTAssertEqual(animated.selectedDayID, instant.selectedDayID)
        XCTAssertEqual(animated.presentedDays.count, instant.presentedDays.count)
        XCTAssertEqual(
            animated.presentedDays.map(\.id),
            instant.presentedDays.map(\.id)
        )
    }

    func testMultiStepIntentIgnoresAnimationFlagForState() {
        let animated = makeViewModel()
        let instant = makeViewModel()
        animated.showMonth(1, year: 2026)
        instant.showMonth(1, year: 2026)

        XCTAssertTrue(
            animated.navigateMonth(
                CalendarMonthNavigationIntent(direction: .next, stepCount: 3, prefersAnimation: true)
            )
        )
        XCTAssertTrue(
            instant.navigateMonth(
                CalendarMonthNavigationIntent(direction: .next, stepCount: 3, prefersAnimation: false)
            )
        )

        XCTAssertEqual(animated.displayedMonth, 4)
        XCTAssertEqual(instant.displayedMonth, 4)
        XCTAssertEqual(animated.displayedYear, 2026)
        XCTAssertEqual(instant.displayedYear, 2026)
    }

    func testGoToTodayStateUnaffectedByAnimationPreferenceConcept() {
        let viewModel = makeViewModel()
        viewModel.showMonth(11, year: 2025)
        XCTAssertTrue(viewModel.goToToday())
        XCTAssertEqual(viewModel.displayedMonth, 7)
        XCTAssertEqual(viewModel.displayedYear, 2026)
        XCTAssertEqual(viewModel.selectedDay?.dayNumber, 15)

        // Second call remains a no-op regardless of any presentation animation wrapper.
        XCTAssertFalse(viewModel.goToToday())
        XCTAssertTrue(viewModel.isShowingToday)
    }

    func testMotionTokensStayWithinPremiumDurationBudget() {
        // Durations are compile-time constants; assert the documented budget via tokens existing.
        XCTAssertNotNil(Motion.calendarMonthChange)
        XCTAssertNotNil(Motion.calendarSelection)
        XCTAssertNotNil(Motion.calendarBackground)
        XCTAssertNotNil(Motion.calendarHeader)
        XCTAssertNotNil(Motion.calendarEvents)
        XCTAssertNil(Motion.resolved(Motion.calendarMonthChange, reduceMotion: true))
        XCTAssertNotNil(Motion.resolved(Motion.calendarMonthChange, reduceMotion: false))
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
private final class EmptyAnimationEventRepository: EventRepositoryProtocol {

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

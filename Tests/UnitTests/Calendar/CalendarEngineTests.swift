//
//  CalendarEngineTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for ``CalendarEngine`` month metrics and navigation math.
final class CalendarEngineTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var engine: CalendarEngine!

    override func setUp() {
        super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
        engine = CalendarEngine(
            calendar: calendar,
            today: date(2026, 7, 15)
        )
    }

    // MARK: - Month Change

    func testMonthByAddingMovesToAdjacentMonth() {
        let next = engine.monthByAdding(1, toMonth: 7, year: 2026)
        XCTAssertEqual(next?.month, 8)
        XCTAssertEqual(next?.year, 2026)

        let previous = engine.monthByAdding(-1, toMonth: 7, year: 2026)
        XCTAssertEqual(previous?.month, 6)
        XCTAssertEqual(previous?.year, 2026)
    }

    // MARK: - Year Change

    func testDecemberToJanuaryIncrementsYear() {
        let next = engine.monthByAdding(1, toMonth: 12, year: 2026)
        XCTAssertEqual(next?.month, 1)
        XCTAssertEqual(next?.year, 2027)
    }

    func testJanuaryToDecemberDecrementsYear() {
        let previous = engine.monthByAdding(-1, toMonth: 1, year: 2026)
        XCTAssertEqual(previous?.month, 12)
        XCTAssertEqual(previous?.year, 2025)
    }

    // MARK: - Different Day Counts

    func testNumberOfDaysForMonthsWithDifferentLengths() {
        XCTAssertEqual(engine.numberOfDays(in: 1, year: 2026), 31)
        XCTAssertEqual(engine.numberOfDays(in: 4, year: 2026), 30)
        XCTAssertEqual(engine.numberOfDays(in: 2, year: 2025), 28)
    }

    func testClampedDayNumberForShorterMonth() {
        XCTAssertEqual(engine.clampedDayNumber(31, month: 4, year: 2026), 30)
        XCTAssertEqual(engine.clampedDayNumber(31, month: 2, year: 2025), 28)
        XCTAssertEqual(engine.clampedDayNumber(15, month: 3, year: 2026), 15)
    }

    func testGenerateDaysAlwaysReturnsFortyTwoCells() {
        for month in 1...12 {
            let days = engine.generateDays(month: month, year: 2026)
            XCTAssertEqual(days.count, CalendarConstants.monthlyGridCellCount, "month \(month)")
        }
    }

    // MARK: - Leap Year

    func testLeapYearFebruaryHasTwentyNineDays() {
        XCTAssertTrue(engine.isLeapYear(2024))
        XCTAssertEqual(engine.numberOfDays(in: 2, year: 2024), 29)
        XCTAssertEqual(engine.clampedDayNumber(31, month: 2, year: 2024), 29)
    }

    func testNonLeapYearFebruaryHasTwentyEightDays() {
        XCTAssertFalse(engine.isLeapYear(2025))
        XCTAssertEqual(engine.numberOfDays(in: 2, year: 2025), 28)
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }
}

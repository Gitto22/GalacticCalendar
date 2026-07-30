//
//  CalendarGenerating.swift
//  GalacticCalendar
//

import Foundation

/// Contract for calendar structure generation.
///
/// Enables the same engine to be reused by monthly views, future weekly
/// views, widgets, and Apple Watch targets without UI coupling.
protocol CalendarGenerating: Sendable {

    /// Returns the current month number (`1...12`).
    func currentMonth() -> Int

    /// Returns the current year.
    func currentYear() -> Int

    /// Returns the day-of-month for the engine's reference "today".
    func currentDayOfMonth() -> Int

    /// Returns whether ``month``/``year`` is the engine's current period.
    func isCurrentPeriod(month: Int, year: Int) -> Bool

    /// Returns the number of days in the provided month.
    func numberOfDays(in month: Int, year: Int) -> Int

    /// Returns whether the provided year is a leap year.
    func isLeapYear(_ year: Int) -> Bool

    /// Returns the month/year obtained by adding ``value`` months to a period.
    ///
    /// Handles December → January and January → December year rollover.
    func monthByAdding(_ value: Int, toMonth month: Int, year: Int) -> (month: Int, year: Int)?

    /// Returns the month/year after applying a navigation intent (swipe / chevrons).
    func period(
        after intent: CalendarMonthNavigationIntent,
        fromMonth month: Int,
        year: Int
    ) -> (month: Int, year: Int)?

    /// Clamps a day-of-month into the valid range for ``month``/``year``.
    func clampedDayNumber(_ day: Int, month: Int, year: Int) -> Int

    /// Resolves a preferred day-of-month for a target period (smart selection).
    func resolveSelectedDay(
        preferredDay: Int?,
        month: Int,
        year: Int
    ) -> SmartDaySelection?

    /// Returns the first day (date) of the provided month.
    func firstDayOfMonth(month: Int, year: Int) -> Date?

    /// Returns how many leading cells are required so the grid starts on Monday.
    func leadingEmptyDayCount(for month: Int, year: Int) -> Int

    /// Generates a full monthly grid (always 42 cells) for the given month/year.
    func generateDays(month: Int, year: Int) -> [CalendarDay]

    /// Generates a full monthly grid for the current month/year.
    func generateCurrentMonth() -> [CalendarDay]

    /// Generates the Monday-Sunday week containing the provided date.
    func generateWeek(containing date: Date) -> [CalendarDay]
}

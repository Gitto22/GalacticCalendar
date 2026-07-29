//
//  CalendarEngine.swift
//  GalacticCalendar
//

import Foundation

/// UI-agnostic calendar structure engine for Galactic Calendar.
///
/// Produces Monday-first ``CalendarDay`` collections for any month.
/// Always fills exactly 42 positions (6 rows × 7 columns).
/// Safe to reuse from monthly UI, weekly UI, widgets, and Apple Watch.
struct CalendarEngine: CalendarGenerating, Sendable {

    // MARK: - Properties

    /// Calendar configured for Monday-first week calculations.
    private let calendar: Calendar

    /// Reference "today" used when marking the current day.
    private let today: Date

    /// Fixed monthly grid capacity required by the approved layout.
    private var monthlyGridCellCount: Int {
        CalendarConstants.monthlyGridCellCount
    }

    // MARK: - Lifecycle

    /// Creates a calendar engine.
    /// - Parameters:
    ///   - calendar: Base calendar. `firstWeekday` is forced to Monday.
    ///   - today: Reference date used for `isToday` checks.
    init(calendar: Calendar = .current, today: Date = Date()) {
        var mondayFirstCalendar = calendar
        mondayFirstCalendar.firstWeekday = 2
        self.calendar = mondayFirstCalendar
        self.today = mondayFirstCalendar.startOfDay(for: today)
    }

    // MARK: - Current Period

    /// Returns the current month number (`1...12`).
    func currentMonth() -> Int {
        calendar.component(.month, from: today)
    }

    /// Returns the current year.
    func currentYear() -> Int {
        calendar.component(.year, from: today)
    }

    // MARK: - Month Metrics

    /// Returns the number of days in the provided month.
    /// - Parameters:
    ///   - month: Month number in `1...12`.
    ///   - year: Full year value.
    /// - Returns: Day count for the month.
    func numberOfDays(in month: Int, year: Int) -> Int {
        guard let firstDay = firstDayOfMonth(month: month, year: year),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return 0
        }

        return range.count
    }

    /// Returns whether the provided year is a leap year.
    /// - Parameter year: Full year value.
    /// - Returns: `true` when February contains 29 days.
    func isLeapYear(_ year: Int) -> Bool {
        numberOfDays(in: 2, year: year) == 29
    }

    /// Returns the first day of the provided month.
    /// - Parameters:
    ///   - month: Month number in `1...12`.
    ///   - year: Full year value.
    /// - Returns: Start-of-day date for day 1, if valid.
    func firstDayOfMonth(month: Int, year: Int) -> Date? {
        date(year: year, month: month, day: 1).map(calendar.startOfDay(for:))
    }

    /// Returns the Monday-based weekday index of the first day of the month.
    ///
    /// `0` means the month already starts on Monday.
    /// `1...6` means that many leading outside-month cells are required.
    /// - Parameters:
    ///   - month: Month number in `1...12`.
    ///   - year: Full year value.
    /// - Returns: Leading empty-day count before day 1.
    func leadingEmptyDayCount(for month: Int, year: Int) -> Int {
        guard let firstDay = firstDayOfMonth(month: month, year: year) else {
            return 0
        }

        return mondayBasedWeekdayIndex(for: firstDay)
    }

    // MARK: - Monthly Generation

    /// Generates the 42-cell grid for the current month and year.
    ///
    /// Uses ``currentMonth()`` and ``currentYear()`` automatically.
    /// - Returns: Monday-first ``CalendarDay`` collection with exactly 42 items.
    func generateCurrentMonth() -> [CalendarDay] {
        generateDays(month: currentMonth(), year: currentYear())
    }

    /// Generates the 42-cell grid for a specific month and year.
    ///
    /// 1. Leading outside-month days so the grid starts on Monday.
    /// 2. Every day of the requested month.
    /// 3. Trailing outside-month days until the collection reaches exactly 42.
    /// - Parameters:
    ///   - month: Month number in `1...12`.
    ///   - year: Full year value.
    /// - Returns: Ordered ``CalendarDay`` values (`count == 42` when inputs are valid).
    func generateDays(month: Int, year: Int) -> [CalendarDay] {
        guard month >= 1, month <= 12 else {
            return []
        }

        var days: [CalendarDay] = []
        days.reserveCapacity(monthlyGridCellCount)

        days.append(contentsOf: makeLeadingDays(month: month, year: year))
        days.append(contentsOf: makeCurrentMonthDays(month: month, year: year))
        days.append(contentsOf: makeTrailingDays(month: month, year: year, currentCount: days.count))

        let grid = Array(days.prefix(monthlyGridCellCount))
        assert(
            grid.count == monthlyGridCellCount || grid.isEmpty,
            "CalendarEngine must produce exactly \(monthlyGridCellCount) cells for a valid month."
        )
        return grid
    }

    // MARK: - Weekly Generation (future surfaces)

    /// Generates the Monday-Sunday week containing the provided date.
    ///
    /// Intended for future weekly views, widgets, and Apple Watch reuse.
    /// - Parameter date: Any date inside the desired week.
    /// - Returns: Exactly seven ``CalendarDay`` values when successful.
    func generateWeek(containing date: Date) -> [CalendarDay] {
        let startOfDay = calendar.startOfDay(for: date)
        let mondayOffset = mondayBasedWeekdayIndex(for: startOfDay)

        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: startOfDay) else {
            return []
        }

        let visibleMonth = calendar.component(.month, from: startOfDay)

        return (0..<CalendarConstants.columnCount).compactMap { offset in
            guard let dayDate = calendar.date(byAdding: .day, value: offset, to: monday) else {
                return nil
            }

            let dayMonth = calendar.component(.month, from: dayDate)
            let membership: CalendarDayMembership
            if dayMonth == visibleMonth {
                membership = .currentMonth
            } else if dayDate < startOfDay {
                membership = .previousMonth
            } else {
                membership = .nextMonth
            }

            return makeDay(from: dayDate, membership: membership)
        }
    }

    // MARK: - Grid Sections

    /// Builds outside-month days that fill the leading Monday gaps.
    private func makeLeadingDays(month: Int, year: Int) -> [CalendarDay] {
        let gap = leadingEmptyDayCount(for: month, year: year)
        guard gap > 0,
              let firstOfMonth = firstDayOfMonth(month: month, year: year) else {
            return []
        }

        return (0..<gap).compactMap { offset in
            let daysBefore = gap - offset
            guard let dayDate = calendar.date(byAdding: .day, value: -daysBefore, to: firstOfMonth) else {
                return nil
            }

            return makeDay(from: dayDate, membership: .previousMonth)
        }
    }

    /// Builds every day belonging to the requested month.
    private func makeCurrentMonthDays(month: Int, year: Int) -> [CalendarDay] {
        let dayCount = numberOfDays(in: month, year: year)
        guard dayCount > 0 else {
            return []
        }

        return (1...dayCount).compactMap { dayNumber in
            guard let dayDate = date(year: year, month: month, day: dayNumber) else {
                return nil
            }

            return makeDay(from: dayDate, membership: .currentMonth)
        }
    }

    /// Builds trailing outside-month days until the grid reaches 42 cells.
    private func makeTrailingDays(month: Int, year: Int, currentCount: Int) -> [CalendarDay] {
        let remaining = monthlyGridCellCount - currentCount
        guard remaining > 0,
              let firstOfMonth = firstDayOfMonth(month: month, year: year),
              let firstOfNextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth) else {
            return []
        }

        return (0..<remaining).compactMap { offset in
            guard let dayDate = calendar.date(byAdding: .day, value: offset, to: firstOfNextMonth) else {
                return nil
            }

            return makeDay(from: dayDate, membership: .nextMonth)
        }
    }

    // MARK: - Day Factory

    /// Creates a ``CalendarDay`` from an absolute date.
    private func makeDay(from dayDate: Date, membership: CalendarDayMembership) -> CalendarDay {
        let startOfDay = calendar.startOfDay(for: dayDate)
        let dayNumber = calendar.component(.day, from: startOfDay)

        return CalendarDay(
            id: makeIdentifier(for: startOfDay, membership: membership),
            date: startOfDay,
            dayNumber: dayNumber,
            membership: membership,
            isToday: calendar.isDate(startOfDay, inSameDayAs: today),
            isSelected: false,
            eventCount: 0,
            eventColors: []
        )
    }

    // MARK: - Helpers

    /// Builds a stable identifier for a grid day.
    private func makeIdentifier(for date: Date, membership: CalendarDayMembership) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(year)-\(month)-\(day)-\(membership.rawValue)"
    }

    /// Creates a date from year/month/day components.
    private func date(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.calendar = calendar
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }

    /// Converts a Gregorian weekday into a Monday-based zero index.
    ///
    /// System calendars use `1 = Sunday ... 7 = Saturday`.
    private func mondayBasedWeekdayIndex(for date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }
}

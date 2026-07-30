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

    /// Returns the day-of-month for the engine's reference "today".
    func currentDayOfMonth() -> Int {
        calendar.component(.day, from: today)
    }

    /// Returns whether ``month``/``year`` matches the engine's current period.
    func isCurrentPeriod(month: Int, year: Int) -> Bool {
        month == currentMonth() && year == currentYear()
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

    /// Returns the month/year obtained by adding ``value`` months to a period.
    ///
    /// Preserves year correctly across December ↔ January boundaries.
    /// - Parameters:
    ///   - value: Month delta (negative = previous, positive = next).
    ///   - month: Month number in `1...12`.
    ///   - year: Full year value.
    /// - Returns: Normalized `(month, year)`, or `nil` when inputs are invalid.
    func monthByAdding(_ value: Int, toMonth month: Int, year: Int) -> (month: Int, year: Int)? {
        guard month >= 1, month <= 12 else {
            return nil
        }
        guard let anchor = firstDayOfMonth(month: month, year: year),
              let shifted = calendar.date(byAdding: .month, value: value, to: anchor) else {
            return nil
        }
        return (
            month: calendar.component(.month, from: shifted),
            year: calendar.component(.year, from: shifted)
        )
    }

    /// Returns the month/year obtained by applying a navigation intent.
    ///
    /// Used by swipe and chevron navigation so multi-step flicks resolve in one jump.
    /// - Parameters:
    ///   - intent: Direction and step count.
    ///   - month: Starting month (`1...12`).
    ///   - year: Starting year.
    /// - Returns: Target period, or `nil` when inputs are invalid.
    func period(
        after intent: CalendarMonthNavigationIntent,
        fromMonth month: Int,
        year: Int
    ) -> (month: Int, year: Int)? {
        monthByAdding(intent.monthOffset, toMonth: month, year: year)
    }

    /// Clamps a day-of-month into the valid range for ``month``/``year``.
    ///
    /// Used when preserving selection across months with different lengths
    /// (e.g. 31 → February becomes 28/29).
    /// - Parameters:
    ///   - day: Preferred day-of-month.
    ///   - month: Target month (`1...12`).
    ///   - year: Target year.
    /// - Returns: A valid day number for that month, or `0` when invalid.
    func clampedDayNumber(_ day: Int, month: Int, year: Int) -> Int {
        let maxDay = numberOfDays(in: month, year: year)
        guard maxDay > 0 else {
            return 0
        }
        return min(max(day, 1), maxDay)
    }

    /// Resolves a preferred day-of-month for a target period (smart selection).
    ///
    /// - Keeps the day when it exists in the target month.
    /// - Otherwise selects the last valid day (31 Jan → 28/29 Feb, 29 Feb leap → 28).
    /// - Parameters:
    ///   - preferredDay: Day-of-month to preserve, if any.
    ///   - month: Target month (`1...12`).
    ///   - year: Target year.
    /// - Returns: Resolved selection, or `nil` when there is no preference / invalid period.
    func resolveSelectedDay(
        preferredDay: Int?,
        month: Int,
        year: Int
    ) -> SmartDaySelection? {
        guard let preferredDay else {
            return nil
        }
        let resolved = clampedDayNumber(preferredDay, month: month, year: year)
        guard resolved > 0 else {
            return nil
        }
        return SmartDaySelection(
            dayNumber: resolved,
            wasClamped: resolved != preferredDay
        )
    }

    /// Inclusive start-of-day dates from ``start`` through ``end``.
    ///
    /// Used by multi-day event placement on the month grid and day lists.
    /// - Parameters:
    ///   - start: Range start instant.
    ///   - end: Range end instant.
    /// - Returns: Ordered day-start dates covering the inclusive span.
    func dayStarts(from start: Date, through end: Date) -> [Date] {
        EventSchedule.dayStarts(from: start, through: end, calendar: calendar)
    }

    /// Returns whether an event schedule overlaps the calendar day of ``day``.
    /// - Parameters:
    ///   - day: Any instant on the queried day.
    ///   - start: Event start.
    ///   - end: Event end, or `nil` for start-only.
    /// - Returns: `true` when the event should appear on that day.
    func eventOccurs(on day: Date, start: Date, end: Date?) -> Bool {
        EventSchedule.occurs(on: day, start: start, end: end, calendar: calendar)
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

//
//  CalendarDay.swift
//  GalacticCalendar
//

import Foundation

/// Position of a day relative to the month being displayed.
enum CalendarDayMembership: String, Sendable, Codable, Hashable {

    // MARK: - Cases

    /// Day belongs to the previous calendar month.
    case previousMonth

    /// Day belongs to the displayed calendar month.
    case currentMonth

    /// Day belongs to the next calendar month.
    case nextMonth
}

/// Domain model representing one day in a Galactic Calendar grid.
struct CalendarDay: Identifiable, Equatable, Sendable, Hashable, Codable {

    // MARK: - Identity

    /// Stable identity derived from the day's date and membership.
    let id: String

    /// Absolute date represented by this cell (start of day).
    let date: Date

    // MARK: - Display Values

    /// Day-of-month number (`1...31`).
    let dayNumber: Int

    /// Membership relative to the displayed month.
    let membership: CalendarDayMembership

    /// Indicates whether the day belongs to the visible month.
    var isCurrentMonth: Bool {
        membership == .currentMonth
    }

    /// Indicates whether the day matches the engine's reference "today".
    let isToday: Bool

    // MARK: - Interaction / Events

    /// Indicates whether the day is currently selected.
    var isSelected: Bool

    /// Total number of events occurring on this day.
    var eventCount: Int

    /// Up to four ``EventColor`` values used by calendar indicators.
    var eventColors: [EventColor]

    /// Indicates whether the day has associated events.
    var hasEvents: Bool {
        eventCount > 0
    }

    /// `true` when more events exist than visible indicator slots.
    var showsEventOverflow: Bool {
        eventCount > 4
    }

    // MARK: - Lifecycle

    /// Creates a calendar day.
    init(
        id: String,
        date: Date,
        dayNumber: Int,
        membership: CalendarDayMembership,
        isToday: Bool,
        isSelected: Bool = false,
        eventCount: Int = 0,
        eventColors: [EventColor] = []
    ) {
        self.id = id
        self.date = date
        self.dayNumber = dayNumber
        self.membership = membership
        self.isToday = isToday
        self.isSelected = isSelected
        self.eventCount = max(0, eventCount)
        self.eventColors = Array(eventColors.prefix(4))
    }
}

// MARK: - Event Annotation

extension CalendarDay {

    /// Returns a copy annotated with events that fall on this day.
    /// - Parameter events: Events whose ``Event/date`` matches this day.
    /// - Returns: Day carrying indicator colors and total count.
    func applyingEvents(_ events: [Event]) -> CalendarDay {
        var copy = self
        copy.eventCount = events.count
        copy.eventColors = Array(events.prefix(4).map(\.color))
        return copy
    }
}

// MARK: - Derived Helpers

extension CalendarDay {

    /// Returns whether the day falls on Saturday or Sunday.
    func isWeekend(using calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    /// Year component of ``date``.
    func year(using calendar: Calendar = .current) -> Int {
        calendar.component(.year, from: date)
    }

    /// Month component of ``date``.
    func month(using calendar: Calendar = .current) -> Int {
        calendar.component(.month, from: date)
    }
}

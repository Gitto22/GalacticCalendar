//
//  CalendarDay.swift
//  GalacticCalendar
//

import Foundation

/// Semantic color tokens for event indicators on a calendar day.
///
/// Kept UI-agnostic so the same values can feed monthly views,
/// weekly views, widgets, and Apple Watch surfaces.
enum CalendarEventColorToken: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    // MARK: - Cases

    /// Purple event indicator.
    case purple

    /// Green event indicator.
    case green

    /// Blue event indicator.
    case blue

    /// Orange event indicator.
    case orange

    // MARK: - Identifiable

    /// Stable identifier matching the token name.
    var id: String { rawValue }
}

/// Domain model representing one day in a Galactic Calendar grid.
///
/// Pure Foundation model with no UIKit/SwiftUI dependencies.
/// Prepared for future event, selection, and sync enrichments.
struct CalendarDay: Identifiable, Equatable, Sendable, Hashable, Codable {

    // MARK: - Identity

    /// Stable identity derived from the day's date and month membership.
    let id: String

    /// Absolute date represented by this cell (start of day).
    let date: Date

    // MARK: - Display Values

    /// Day-of-month number (`1...31`).
    let dayNumber: Int

    /// Indicates whether the day belongs to the visible month.
    let isCurrentMonth: Bool

    /// Indicates whether the day matches the engine's reference "today".
    let isToday: Bool

    // MARK: - Interaction / Events (prepared)

    /// Indicates whether the day is currently selected.
    var isSelected: Bool

    /// Indicates whether the day has associated events.
    var hasEvents: Bool

    /// Event indicator color tokens for future event wiring.
    var eventColors: [CalendarEventColorToken]

    // MARK: - Lifecycle

    /// Creates a calendar day.
    /// - Parameters:
    ///   - id: Stable identity.
    ///   - date: Absolute date for the cell.
    ///   - dayNumber: Day-of-month number.
    ///   - isCurrentMonth: Whether the day is inside the visible month.
    ///   - isToday: Whether the day is today.
    ///   - isSelected: Whether the day is selected.
    ///   - hasEvents: Whether the day has events.
    ///   - eventColors: Event indicator tokens.
    init(
        id: String,
        date: Date,
        dayNumber: Int,
        isCurrentMonth: Bool,
        isToday: Bool,
        isSelected: Bool = false,
        hasEvents: Bool = false,
        eventColors: [CalendarEventColorToken] = []
    ) {
        self.id = id
        self.date = date
        self.dayNumber = dayNumber
        self.isCurrentMonth = isCurrentMonth
        self.isToday = isToday
        self.isSelected = isSelected
        self.hasEvents = hasEvents
        self.eventColors = Array(eventColors.prefix(4))
    }
}

// MARK: - Derived Helpers

extension CalendarDay {

    /// Returns whether the day falls on Saturday or Sunday.
    /// - Parameter calendar: Calendar used for weekday calculation.
    /// - Returns: `true` when the date is a weekend day.
    func isWeekend(using calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    /// Year component of ``date``.
    /// - Parameter calendar: Calendar used for component extraction.
    /// - Returns: Full year value.
    func year(using calendar: Calendar = .current) -> Int {
        calendar.component(.year, from: date)
    }

    /// Month component of ``date``.
    /// - Parameter calendar: Calendar used for component extraction.
    /// - Returns: Month number in `1...12`.
    func month(using calendar: Calendar = .current) -> Int {
        calendar.component(.month, from: date)
    }
}

//
//  CalendarConstants.swift
//  GalacticCalendar
//

import Foundation

/// Calendar-related immutable constants.
enum CalendarConstants {

    // MARK: - Structure

    /// Number of months represented by the approved space backgrounds.
    static let monthBackgroundCount = 12

    /// Number of columns in the monthly grid.
    static let columnCount = 7

    /// Maximum number of rows in the monthly grid.
    static let maxRowCount = 6

    /// Number of day cells in the approved monthly grid (6 rows × 7 columns).
    static let sampleCellCount = columnCount * maxRowCount

    /// Alias for the fixed monthly grid capacity used by ``CalendarEngine``.
    static let monthlyGridCellCount = sampleCellCount

    /// Maximum event indicator dots rendered under a day number.
    static let maxEventIndicators = 4

    // MARK: - Year Picker

    /// Inclusive lower bound of the default year picker range.
    static let yearPickerLowerBound = 2000

    /// Inclusive upper bound of the default year picker range.
    static let yearPickerUpperBound = 2100

    // MARK: - Swipe

    /// Minimum horizontal translation (points) to commit a month swipe.
    static let monthSwipeMinimumDistance: CGFloat = 56

    /// Horizontal motion must dominate vertical by at least this factor.
    static let monthSwipeHorizontalDominance: CGFloat = 1.15

    // MARK: - Smart Daily Agenda (Sprint 6.8)

    /// Presentation alias of Domain ``AgendaTimelineBuilder/Defaults/workingDayStartHour``.
    static let agendaWorkingDayStartHour: Int = AgendaTimelineBuilder.Defaults.workingDayStartHour

    /// Presentation alias of Domain ``AgendaTimelineBuilder/Defaults/workingDayEndHour``.
    static let agendaWorkingDayEndHour: Int = AgendaTimelineBuilder.Defaults.workingDayEndHour

    /// Presentation alias of Domain ``AgendaTimelineBuilder/Defaults/defaultEventDuration``.
    static let agendaDefaultEventDuration: TimeInterval = AgendaTimelineBuilder.Defaults.defaultEventDuration
}

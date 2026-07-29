//
//  CalendarDay+Presentation.swift
//  GalacticCalendar
//

import SwiftUI

/// Presentation mapping from domain ``CalendarDay`` values to UI tokens.
enum CalendarDayPresentationMapper {

    // MARK: - Mapping

    /// Maps domain event color tokens to Design System colors.
    /// - Parameter tokens: Domain event color tokens.
    /// - Returns: Colors from ``ColorPalette``.
    static func colors(for tokens: [CalendarEventColorToken]) -> [Color] {
        tokens.prefix(CalendarConstants.maxEventIndicators).map(color(for:))
    }

    /// Maps a single domain token to a Design System color.
    /// - Parameter token: Domain event color token.
    /// - Returns: Matching ``ColorPalette`` color.
    static func color(for token: CalendarEventColorToken) -> Color {
        switch token {
        case .purple:
            ColorPalette.eventIndicatorPurple
        case .green:
            ColorPalette.eventIndicatorGreen
        case .blue:
            ColorPalette.eventIndicatorBlue
        case .orange:
            ColorPalette.eventIndicatorOrange
        }
    }

    /// Builds prepared cell states from a domain day.
    /// - Parameter day: Domain calendar day.
    /// - Returns: Visual states for ``CalendarDayCell``.
    static func states(for day: CalendarDay) -> Set<CalendarDayCellState> {
        var states: Set<CalendarDayCellState> = []

        if day.isCurrentMonth == false {
            states.insert(.outsideMonth)
        }

        if day.isToday {
            states.insert(.current)
        }

        if day.isSelected {
            states.insert(.selected)
        }

        if day.hasEvents {
            states.insert(.withEvent)
        }

        if states.isEmpty {
            states.insert(.normal)
        }

        return states
    }
}

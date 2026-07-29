//
//  CalendarDay+Presentation.swift
//  GalacticCalendar
//

import SwiftUI

/// Presentation mapping from domain ``CalendarDay`` values to UI tokens.
enum CalendarDayPresentationMapper {

    // MARK: - Mapping

    /// Maps domain ``EventColor`` values to Design System colors.
    static func colors(for eventColors: [EventColor]) -> [Color] {
        eventColors
            .prefix(CalendarConstants.maxEventIndicators)
            .map(ColorPalette.color(for:))
    }

    /// Builds cell states from a domain day.
    static func states(for day: CalendarDay) -> Set<CalendarDayCellState> {
        var states: Set<CalendarDayCellState> = []

        switch day.membership {
        case .previousMonth:
            states.insert(.previousMonth)
        case .nextMonth:
            states.insert(.nextMonth)
        case .currentMonth:
            break
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

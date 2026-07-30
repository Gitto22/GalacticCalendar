//
//  CalendarEventIndicator.swift
//  GalacticCalendar
//

import Foundation

/// Presentation token for a calendar-grid event indicator.
///
/// Sprint 6.4 keeps the existing color-dot UI. This type centralizes the
/// payload so future sprints can add priority/tag accents without changing
/// ``CalendarDay``'s public event-annotation API abruptly.
struct CalendarEventIndicator: Equatable, Sendable, Hashable, Identifiable, Codable {

    // MARK: - Properties

    /// Stable id (typically the master event id string).
    let id: String

    /// Color token shown by the current grid indicators.
    let color: EventColor

    /// Reserved: priority for future indicator variants (not rendered yet).
    let priority: EventPriority?

    // MARK: - Lifecycle

    init(id: String, color: EventColor, priority: EventPriority? = nil) {
        self.id = id
        self.color = color
        self.priority = priority
    }

    /// Builds indicators from domain events (max four, matching the approved dots).
    static func indicators(from events: [Event], limit: Int = 4) -> [CalendarEventIndicator] {
        Array(events.prefix(limit)).map { event in
            CalendarEventIndicator(
                id: event.id.uuidString,
                color: event.color,
                priority: event.priority
            )
        }
    }
}

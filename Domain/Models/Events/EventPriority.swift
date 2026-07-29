//
//  EventPriority.swift
//  GalacticCalendar
//

import Foundation

/// Priority level for a Galactic Calendar event.
enum EventPriority: String, Sendable, CaseIterable, Codable, Hashable, Identifiable, Comparable {

    // MARK: - Cases

    /// Low priority.
    case low

    /// Medium priority.
    case medium

    /// High priority.
    case high

    /// Critical priority.
    case critical

    // MARK: - Identifiable

    /// Stable identifier matching the raw value.
    var id: String { rawValue }

    // MARK: - Comparable

    /// Sort order from lowest to highest urgency.
    private var sortIndex: Int {
        switch self {
        case .low: 0
        case .medium: 1
        case .high: 2
        case .critical: 3
        }
    }

    static func < (lhs: EventPriority, rhs: EventPriority) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }
}

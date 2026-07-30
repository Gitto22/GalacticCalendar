//
//  EventPriority.swift
//  GalacticCalendar
//

import Foundation

/// Priority level for a Galactic Calendar event.
///
/// ## Persistence
/// Raw values are CloudKit-friendly. Legacy `medium` / `critical` decode as
/// ``normal`` / ``urgent`` via ``init(persisted:)``.
enum EventPriority: String, Sendable, CaseIterable, Codable, Hashable, Identifiable, Comparable {

    // MARK: - Cases

    /// Low priority (Baja).
    case low

    /// Normal priority (Normal).
    case normal

    /// High priority (Alta).
    case high

    /// Urgent priority (Urgente).
    case urgent

    // MARK: - Identifiable

    /// Stable identifier matching the persistence raw value.
    var id: String { rawValue }

    // MARK: - Persistence

    /// Decodes a stored raw value, mapping legacy tokens.
    /// - Parameter rawValue: Persisted string.
    /// - Returns: Priority, or `nil` when unknown.
    init?(persisted rawValue: String) {
        if let value = EventPriority(rawValue: rawValue) {
            self = value
            return
        }
        switch rawValue {
        case "medium":
            self = .normal
        case "critical":
            self = .urgent
        default:
            return nil
        }
    }

    // MARK: - Comparable

    /// Sort order from lowest to highest urgency.
    private var sortIndex: Int {
        switch self {
        case .low: 0
        case .normal: 1
        case .high: 2
        case .urgent: 3
        }
    }

    static func < (lhs: EventPriority, rhs: EventPriority) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }
}

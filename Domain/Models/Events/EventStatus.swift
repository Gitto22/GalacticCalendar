//
//  EventStatus.swift
//  GalacticCalendar
//

import Foundation

/// Lifecycle status for a Galactic Calendar event.
enum EventStatus: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    // MARK: - Cases

    /// Event is pending.
    case pending

    /// Event is in progress.
    case inProgress

    /// Event has been completed.
    case completed

    /// Event has been cancelled.
    case cancelled

    // MARK: - Identifiable

    /// Stable identifier matching the raw value.
    var id: String { rawValue }
}

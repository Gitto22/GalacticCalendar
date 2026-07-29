//
//  EventCategory.swift
//  GalacticCalendar
//

import Foundation

/// Category classification for a Galactic Calendar event.
enum EventCategory: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    // MARK: - Cases

    /// Work-related event.
    case work

    /// Personal event.
    case personal

    /// Health-related event.
    case health

    /// Finance-related event.
    case finances

    /// Family-related event.
    case family

    /// Study-related event.
    case studies

    /// Travel-related event.
    case travel

    /// Uncategorized or custom event.
    case other

    // MARK: - Identifiable

    /// Stable identifier matching the raw value.
    var id: String { rawValue }
}

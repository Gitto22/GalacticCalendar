//
//  EventColor.swift
//  GalacticCalendar
//

import Foundation

/// Domain color token for a Galactic Calendar event.
///
/// Presentation maps these values to ``ColorPalette`` later.
/// Kept UI-agnostic for Domain purity.
enum EventColor: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    // MARK: - Cases

    /// Green event accent.
    case green

    /// Yellow event accent.
    case yellow

    /// Orange event accent.
    case orange

    /// Red event accent.
    case red

    // MARK: - Identifiable

    /// Stable identifier matching the raw value.
    var id: String { rawValue }
}

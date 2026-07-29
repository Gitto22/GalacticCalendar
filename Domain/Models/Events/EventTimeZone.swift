//
//  EventTimeZone.swift
//  GalacticCalendar
//

import Foundation

/// Time zone helpers for event scheduling (CloudKit-ready IANA identifiers).
enum EventTimeZone: Sendable {

    // MARK: - Editor Presets

    /// Identifiers exposed in the event editor timezone menu.
    ///
    /// Kept small for UX; full zone catalogs can replace this list later.
    static var editorSelectableIdentifiers: [String] {
        var identifiers: [String] = [
            TimeZone.current.identifier,
            "UTC",
            "Europe/Madrid",
            "Europe/London",
            "America/New_York",
            "America/Los_Angeles",
            "America/Mexico_City",
            "Asia/Tokyo"
        ]
        // Preserve order while removing duplicates.
        var seen = Set<String>()
        return identifiers.filter { seen.insert($0).inserted }
    }

    // MARK: - Resolution

    /// Resolves a stored identifier to a ``TimeZone``, falling back to current.
    /// - Parameter identifier: IANA identifier.
    /// - Returns: Resolved time zone.
    static func timeZone(for identifier: String) -> TimeZone {
        TimeZone(identifier: identifier) ?? .current
    }

    /// Localized display name for an identifier.
    /// - Parameter identifier: IANA identifier.
    /// - Returns: User-facing name, or the raw identifier when localization is unavailable.
    static func displayName(for identifier: String) -> String {
        let zone = timeZone(for: identifier)
        return zone.localizedName(for: .standard, locale: .autoupdatingCurrent) ?? identifier
    }

    /// `true` when `identifier` maps to a known ``TimeZone``.
    /// - Parameter identifier: Candidate IANA id.
    static func isValidIdentifier(_ identifier: String) -> Bool {
        TimeZone(identifier: identifier) != nil
    }
}

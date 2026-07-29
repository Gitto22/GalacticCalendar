//
//  AppConstants.swift
//  GalacticCalendar
//

import Foundation

/// Application-wide immutable constants for Galactic Calendar.
enum AppConstants {

    // MARK: - Identity

    /// User-facing application name.
    static let appName = "Galactic Calendar"

    /// Bundle identifier fallback when the host bundle value is unavailable.
    static let defaultBundleIdentifier = "com.albancal.GalacticCalendar"

    // MARK: - Support

    /// Semantic module name used in logging and diagnostics.
    static let diagnosticsSubsystem = "GalacticCalendar"
}

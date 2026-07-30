//
//  FeatureFlagCatalog.swift
//  GalacticCalendar
//

import Foundation

/// Default availability map for all known feature flags.
enum FeatureFlagCatalog {

    // MARK: - Defaults

    /// Baseline flag states for a production-ready scaffold.
    ///
    /// All reserved capabilities remain disabled until explicitly enabled.
    static let defaults: [FeatureFlag: Bool] = [
        .cloudKitSync: false,
        .widgets: false,
        .appleWatch: false,
        .eventKit: false,
        .sharing: false,
        .universeMessages: true,
        .storeKit: false,
        .backup: false,
        .statistics: false,
        .additionalThemes: false
    ]

    // MARK: - Lookup

    /// Returns the default value for the provided flag.
    /// - Parameter flag: Feature flag to resolve.
    /// - Returns: Default enabled state.
    static func defaultValue(for flag: FeatureFlag) -> Bool {
        defaults[flag] ?? false
    }
}

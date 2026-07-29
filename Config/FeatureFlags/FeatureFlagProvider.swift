//
//  FeatureFlagProvider.swift
//  GalacticCalendar
//

import Foundation

/// Resolves feature flag values at runtime.
protocol FeatureFlagProviding: Sendable {

    /// Returns whether the given feature flag is enabled.
    /// - Parameter flag: Flag to evaluate.
    /// - Returns: `true` when the capability may be used.
    func isEnabled(_ flag: FeatureFlag) -> Bool
}

/// Default feature flag provider backed by ``FeatureFlagCatalog``.
struct DefaultFeatureFlagProvider: FeatureFlagProviding {

    // MARK: - Properties

    /// Optional overrides applied on top of catalog defaults.
    private let overrides: [FeatureFlag: Bool]

    // MARK: - Lifecycle

    /// Creates a provider with optional per-flag overrides.
    /// - Parameter overrides: Values that replace catalog defaults.
    init(overrides: [FeatureFlag: Bool] = [:]) {
        self.overrides = overrides
    }

    // MARK: - FeatureFlagProviding

    /// Resolves a flag using overrides first, then catalog defaults.
    /// - Parameter flag: Flag to evaluate.
    /// - Returns: Effective enabled state.
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        if let override = overrides[flag] {
            return override
        }

        return FeatureFlagCatalog.defaultValue(for: flag)
    }
}

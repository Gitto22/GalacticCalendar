//
//  AppConfiguration.swift
//  GalacticCalendar
//

import Foundation

/// Central application configuration composed at launch.
///
/// Acts as the configuration façade for the Composition Root and
/// downstream modules without exposing infrastructure details.
@MainActor
@Observable
final class AppConfiguration {

    // MARK: - Properties

    /// Active build environment.
    let environment: AppEnvironment

    /// Bundle metadata for the running target.
    let bundle: BundleConfiguration

    /// Platform detection for iPhone, iPad, and macOS.
    let platform: PlatformConfiguration

    /// Feature flag resolver used across the application.
    let featureFlags: any FeatureFlagProviding

    /// Environment provider used to obtain the active environment.
    private let environmentProvider: any EnvironmentProviding

    // MARK: - Lifecycle

    /// Creates the application configuration graph.
    /// - Parameters:
    ///   - environmentProvider: Source of the active environment.
    ///   - bundle: Bundle metadata provider.
    ///   - platform: Platform detection values.
    ///   - featureFlags: Feature flag resolver.
    init(
        environmentProvider: any EnvironmentProviding = DefaultEnvironmentProvider(),
        bundle: BundleConfiguration = BundleConfiguration(),
        platform: PlatformConfiguration = PlatformConfiguration(),
        featureFlags: any FeatureFlagProviding = DefaultFeatureFlagProvider()
    ) {
        self.environmentProvider = environmentProvider
        self.environment = environmentProvider.environment
        self.bundle = bundle
        self.platform = platform
        self.featureFlags = featureFlags
    }

    // MARK: - Feature Flags

    /// Convenience accessor for feature flag evaluation.
    /// - Parameter flag: Flag to evaluate.
    /// - Returns: Whether the flag is enabled.
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        featureFlags.isEnabled(flag)
    }
}

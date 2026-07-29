//
//  AppEnvironment.swift
//  GalacticCalendar
//

import Foundation

/// Describes the runtime build environment used by Galactic Calendar.
enum AppEnvironment: String, Sendable, CaseIterable, Identifiable {

    // MARK: - Cases

    /// Local development builds.
    case development

    /// Pre-production validation builds.
    case staging

    /// App Store and TestFlight production builds.
    case production

    // MARK: - Identifiable

    /// Stable identifier for the environment.
    var id: String { rawValue }

    // MARK: - Current Environment

    /// Resolves the active environment from compile-time flags.
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }

    // MARK: - Capabilities

    /// Indicates whether diagnostic logging should be enabled.
    var isLoggingEnabled: Bool {
        switch self {
        case .development, .staging:
            true
        case .production:
            false
        }
    }

    /// Indicates whether non-production diagnostics may surface in the UI.
    var allowsDebugOverlays: Bool {
        self == .development
    }
}

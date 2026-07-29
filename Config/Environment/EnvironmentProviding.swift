//
//  EnvironmentProviding.swift
//  GalacticCalendar
//

import Foundation

/// Provides access to the active application environment.
protocol EnvironmentProviding: Sendable {

    /// The environment associated with the current build.
    var environment: AppEnvironment { get }
}

/// Default environment provider backed by ``AppEnvironment/current``.
struct DefaultEnvironmentProvider: EnvironmentProviding {

    // MARK: - EnvironmentProviding

    /// Returns the compile-time resolved application environment.
    var environment: AppEnvironment {
        .current
    }
}

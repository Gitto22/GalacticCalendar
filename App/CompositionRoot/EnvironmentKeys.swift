//
//  EnvironmentKeys.swift
//  GalacticCalendar
//

import Foundation
import SwiftUI

/// SwiftUI environment accessors for infrastructure dependencies.
///
/// Observable dependencies are injected with ``View/environment(_:)``.
/// These helpers document the supported environment surface for the shell.
enum AppEnvironmentKeys {

    // MARK: - Guidance

    /// Lists the observable dependencies expected by the application shell.
    static let observableDependencies = [
        "DependencyContainer",
        "AppConfiguration",
        "NavigationManager",
        "AppRouter",
        "ThemeManager",
        "EventPersistenceService",
        "EventTemplateService"
    ]
}

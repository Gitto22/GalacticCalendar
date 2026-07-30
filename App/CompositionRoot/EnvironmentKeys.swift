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

    /// Observable dependencies injected into the application Environment (QA-07).
    ///
    /// `NavigationManager` / `AppRouter` remain on ``DependencyContainer``
    /// (reserved push stack, QA-06) but are **not** Environment-injected until
    /// product navigation uses them.
    static let observableDependencies = [
        "DependencyContainer",
        "AppConfiguration",
        "ThemeManager",
        "CalendarAppearanceManager",
        "EventPersistenceService",
        "EventTemplateService"
    ]
}

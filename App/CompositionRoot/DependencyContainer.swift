//
//  DependencyContainer.swift
//  GalacticCalendar
//

import Foundation

/// Composition Root that wires infrastructure dependencies for the app shell.
///
/// Feature modules are intentionally not constructed here yet.
@MainActor
@Observable
final class DependencyContainer {

    // MARK: - Configuration

    /// Application configuration façade.
    let appConfiguration: AppConfiguration

    // MARK: - Navigation

    /// Navigation stack owner.
    let navigationManager: NavigationManager

    /// High-level navigation coordinator.
    let appRouter: AppRouter

    // MARK: - Appearance

    /// Theme manager for system appearance preferences.
    let themeManager: ThemeManager

    // MARK: - Lifecycle

    /// Builds the infrastructure graph required to launch the application shell.
    init() {
        let configuration = AppConfiguration()
        self.appConfiguration = configuration

        let navigationManager = NavigationManager()
        self.navigationManager = navigationManager
        self.appRouter = AppRouter(navigationManager: navigationManager)

        self.themeManager = ThemeManager(
            allowsAdditionalThemes: configuration.isEnabled(.additionalThemes)
        )
    }
}

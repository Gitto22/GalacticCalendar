//
//  AppRouter.swift
//  GalacticCalendar
//

import Foundation

/// High-level navigation coordinator for Galactic Calendar.
///
/// Translates application-level navigation intents into
/// ``NavigationManager`` stack operations.
@MainActor
@Observable
final class AppRouter {

    // MARK: - Properties

    /// Low-level navigation stack manager.
    let navigationManager: NavigationManager

    // MARK: - Lifecycle

    /// Creates a router bound to a navigation manager.
    /// - Parameter navigationManager: Stack owner used for routing.
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }

    // MARK: - Routing

    /// Navigates to the application root.
    func showRoot() {
        navigationManager.popToRoot()
    }

    /// Pushes a destination onto the stack.
    /// - Parameter route: Destination to present.
    func navigate(to route: Route) {
        switch route {
        case .root:
            showRoot()
        }
    }
}

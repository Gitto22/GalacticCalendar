//
//  AppRouter.swift
//  GalacticCalendar
//

import Foundation

/// Reserved high-level coordinator for future shell push intents.
///
/// ## Private Beta (QA-06)
/// Product flows do not call this type. Prefer ViewModel-owned
/// `present*` / `dismiss*` + modal modifiers. Kept wired in DI for later
/// deep links without introducing parallel routers in features.
@MainActor
@Observable
final class AppRouter {

    // MARK: - Properties

    /// Low-level navigation stack manager (reserved).
    let navigationManager: NavigationManager

    // MARK: - Lifecycle

    /// Creates a router bound to a navigation manager.
    /// - Parameter navigationManager: Stack owner used for routing.
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }

    // MARK: - Routing

    /// Navigates to the application root (clears reserved push path).
    func showRoot() {
        navigationManager.popToRoot()
    }

    /// Pushes a destination onto the reserved stack.
    /// - Parameter route: Destination to present.
    func navigate(to route: Route) {
        switch route {
        case .root:
            showRoot()
        }
    }
}

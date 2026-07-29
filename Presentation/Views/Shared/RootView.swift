//
//  RootView.swift
//  GalacticCalendar
//

import SwiftUI

/// Root presentation container hosted by the application scene.
///
/// Currently visualizes the monthly background only.
/// Calendar, events, and header remain deferred.
struct RootView: View {

    // MARK: - Environment

    /// Navigation stack owner injected by the Composition Root.
    @Environment(NavigationManager.self) private var navigationManager

    /// Appearance preferences injected by the Composition Root.
    @Environment(ThemeManager.self) private var themeManager

    // MARK: - Body

    var body: some View {
        NavigationStack(path: Bindable(navigationManager).path) {
            MonthBackgroundView()
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .preferredColorScheme(themeManager.preferredColorScheme)
    }

    // MARK: - Destinations

    /// Resolves a view for the provided route.
    /// - Parameter route: Navigation destination.
    /// - Returns: Destination view.
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .root:
            MonthBackgroundView()
        }
    }
}

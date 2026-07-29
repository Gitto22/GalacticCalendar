//
//  RootView.swift
//  GalacticCalendar
//

import SwiftUI

/// Root presentation container hosted by the application scene.
///
/// Hosts the approved ``HomeView`` as the main screen.
struct RootView: View {

    // MARK: - Environment

    /// Navigation stack owner injected by the Composition Root.
    @Environment(NavigationManager.self) private var navigationManager

    /// Appearance preferences injected by the Composition Root.
    @Environment(ThemeManager.self) private var themeManager

    // MARK: - Body

    var body: some View {
        NavigationStack(path: Bindable(navigationManager).path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
                #if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
                #endif
        }
        .preferredColorScheme(themeManager.preferredColorScheme)
    }

    // MARK: - Destinations

    /// Resolves a view for the provided route.
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .root:
            HomeView()
        }
    }
}

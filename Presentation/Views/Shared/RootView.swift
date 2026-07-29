//
//  RootView.swift
//  GalacticCalendar
//

import SwiftUI

/// Root presentation container hosted by the application scene.
///
/// Hosts navigation infrastructure only. Calendar and event UI are not
/// connected yet.
struct RootView: View {

    // MARK: - Environment

    /// Navigation stack owner injected by the Composition Root.
    @Environment(NavigationManager.self) private var navigationManager

    /// Appearance preferences injected by the Composition Root.
    @Environment(ThemeManager.self) private var themeManager

    /// Application configuration injected by the Composition Root.
    @Environment(AppConfiguration.self) private var appConfiguration

    // MARK: - Body

    var body: some View {
        NavigationStack(path: Bindable(navigationManager).path) {
            shellContent
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .preferredColorScheme(themeManager.preferredColorScheme)
    }

    // MARK: - Shell

    /// Minimal shell content used until feature modules are connected.
    @ViewBuilder
    private var shellContent: some View {
        VStack(spacing: 12) {
            Text(appConfiguration.bundle.displayName)
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text(appConfiguration.environment.rawValue.capitalized)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(appConfiguration.platform.platform.rawValue)
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(AppConstants.appName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Destinations

    /// Resolves a view for the provided route.
    /// - Parameter route: Navigation destination.
    /// - Returns: Destination view.
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .root:
            shellContent
        }
    }
}

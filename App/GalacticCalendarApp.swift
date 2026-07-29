//
//  GalacticCalendarApp.swift
//  GalacticCalendar
//

import SwiftUI

/// Application entry point for Galactic Calendar across iPhone, iPad, and macOS.
@main
struct GalacticCalendarApp: App {

    // MARK: - Dependencies

    /// Composition Root owning infrastructure dependencies.
    @State private var container = DependencyContainer()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(container.appConfiguration)
                .environment(container.navigationManager)
                .environment(container.appRouter)
                .environment(container.themeManager)
        }
    }
}

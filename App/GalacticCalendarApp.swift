//
//  GalacticCalendarApp.swift
//  GalacticCalendar
//

import SwiftUI
import SwiftData

/// Application entry point for Galactic Calendar across iPhone, iPad, and macOS.
@main
struct GalacticCalendarApp: App {

    // MARK: - Dependencies

    /// Composition Root owning infrastructure dependencies.
    @State private var container = DependencyContainer()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            rootContent
                .environment(container)
                .environment(container.appConfiguration)
                .environment(container.themeManager)
                .environment(container.calendarAppearanceManager)
                .environment(container.eventPersistenceService)
                .environment(container.eventTemplateService)
                // NavigationManager / AppRouter stay on the container (QA-06
                // reserved push stack) but are not Environment-injected until
                // product navigation consumes them (QA-07).
        }
    }

    // MARK: - Private

    /// Attaches ``modelContainer`` only when the on-disk store opened successfully.
    @ViewBuilder
    private var rootContent: some View {
        if let modelContainer = container.modelContainer {
            RootView()
                .modelContainer(modelContainer)
        } else {
            RootView()
        }
    }
}

//
//  DependencyContainer.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// Composition Root that wires infrastructure and persistence dependencies.
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

    // MARK: - Persistence

    /// SwiftData model container for local storage (CloudKit-ready configuration).
    let modelContainer: ModelContainer

    /// Event persistence entry point for ViewModels.
    let eventPersistenceService: EventPersistenceService

    // MARK: - Lifecycle

    /// Builds the infrastructure graph required to launch the application.
    init() {
        let configuration = AppConfiguration()
        self.appConfiguration = configuration

        let navigationManager = NavigationManager()
        self.navigationManager = navigationManager
        self.appRouter = AppRouter(navigationManager: navigationManager)

        self.themeManager = ThemeManager(
            allowsAdditionalThemes: configuration.isEnabled(.additionalThemes)
        )

        do {
            let container = try ModelContainerFactory.make(
                enableCloudKit: configuration.isEnabled(.cloudKitSync)
            )
            self.modelContainer = container

            let repository = EventRepository(modelContext: container.mainContext)
            self.eventPersistenceService = EventPersistenceService(repository: repository)
        } catch {
            // Fallback to in-memory store so the app can still launch if disk setup fails.
            let fallback = try! ModelContainerFactory.make(inMemory: true, enableCloudKit: false)
            self.modelContainer = fallback
            let repository = EventRepository(modelContext: fallback.mainContext)
            self.eventPersistenceService = EventPersistenceService(repository: repository)
        }
    }
}

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

    /// Non-`nil` when the disk store failed and the app fell back to in-memory.
    ///
    /// ViewModels / root UI should surface this so the user knows data is ephemeral.
    private(set) var persistenceLaunchError: EventPersistenceError?

    // MARK: - Notifications

    /// Local reminder scheduling service (also injected into ``eventPersistenceService``).
    let notificationService: NotificationService

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

        let notificationRepository = NotificationRepository()
        let notificationService = NotificationService(repository: notificationRepository)
        self.notificationService = notificationService

        let catalog = EventCatalogService()

        do {
            let container = try ModelContainerFactory.make(
                enableCloudKit: configuration.isEnabled(.cloudKitSync)
            )
            self.modelContainer = container
            self.persistenceLaunchError = nil
            let repository = EventRepository(modelContext: container.mainContext)
            self.eventPersistenceService = EventPersistenceService(
                repository: repository,
                catalog: catalog,
                notificationService: notificationService
            )
        } catch {
            do {
                let fallback = try ModelContainerFactory.make(
                    inMemory: true,
                    enableCloudKit: false
                )
                self.modelContainer = fallback
                self.persistenceLaunchError = .storeUnavailable
                let repository = EventRepository(modelContext: fallback.mainContext)
                self.eventPersistenceService = EventPersistenceService(
                    repository: repository,
                    catalog: catalog,
                    notificationService: notificationService
                )
            } catch {
                // In-memory SwiftData creation failed — the process cannot continue safely.
                preconditionFailure(
                    "Galactic Calendar could not create a ModelContainer (disk and in-memory failed): \(error)"
                )
            }
        }
    }
}

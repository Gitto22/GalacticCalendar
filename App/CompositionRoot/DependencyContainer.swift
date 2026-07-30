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

    /// Theme manager for system appearance preferences and theme packs.
    let themeManager: ThemeManager

    /// Calendar month/background appearance (header titles + monthly imagery).
    let calendarAppearanceManager: CalendarAppearanceManager

    // MARK: - Persistence

    /// SwiftData model container when the on-disk store opened successfully.
    ///
    /// `nil` when storage is unavailable — the app must not attach an ephemeral
    /// in-memory store for normal use.
    let modelContainer: ModelContainer?

    /// Event persistence entry point for ViewModels.
    let eventPersistenceService: EventPersistenceService

    /// Global store availability mirrored onto ``eventPersistenceService``.
    private(set) var storageAvailability: StorageAvailability

    /// Non-`nil` when launch could not open the persistent store.
    private(set) var persistenceLaunchError: EventPersistenceError?

    // MARK: - Notifications

    /// Local reminder scheduling (injected into ``eventPersistenceService`` only).
    private let notificationService: NotificationService

    // MARK: - Universe Messages

    /// Catalog repository (sole data access for Universe Messages).
    let universeMessageRepository: any UniverseMessageRepositoryProtocol

    /// Day-selection engine.
    let universeMessageEngine: UniverseMessageEngine

    /// Application service for catalog mutations (favorites).
    let universeMessageService: UniverseMessageService

    // MARK: - Event Templates

    /// Offline event-template façade (independent of the event catalog).
    let eventTemplateService: EventTemplateService

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
        self.calendarAppearanceManager = CalendarAppearanceManager()

        let notificationRepository = NotificationRepository()
        let notificationService = NotificationService(repository: notificationRepository)
        self.notificationService = notificationService

        let catalog = EventCatalogService()

        let openedContainer: ModelContainer?
        let availability: StorageAvailability
        let launchError: EventPersistenceError?

        do {
            openedContainer = try ModelContainerFactory.make(
                enableCloudKit: configuration.isEnabled(.cloudKitSync)
            )
            availability = .available
            launchError = nil
        } catch {
            PersistenceLog.storeOpenFailed(error)
            PersistenceLog.storageUnavailableEntered()
            openedContainer = nil
            availability = .unavailable
            launchError = .storeUnavailable
        }

        self.modelContainer = openedContainer
        self.storageAvailability = availability
        self.persistenceLaunchError = launchError

        if let openedContainer {
            let eventRepository = EventRepository(modelContext: openedContainer.mainContext)
            self.eventPersistenceService = EventPersistenceService(
                repository: eventRepository,
                catalog: catalog,
                notificationService: notificationService,
                storageAvailability: .available
            )

            let universeRepository = UniverseMessageRepository(
                modelContext: openedContainer.mainContext
            )
            self.universeMessageRepository = universeRepository
            let universeEngine = UniverseMessageEngine(repository: universeRepository)
            self.universeMessageEngine = universeEngine
            self.universeMessageService = UniverseMessageService(
                repository: universeRepository,
                engine: universeEngine,
                storageAvailabilityProvider: { [weak self] in
                    self?.storageAvailability ?? .unavailable
                }
            )

            let templateRepository = EventTemplateRepository(
                modelContext: openedContainer.mainContext
            )
            self.eventTemplateService = EventTemplateService(
                repository: templateRepository,
                storageAvailabilityProvider: { [weak self] in
                    self?.storageAvailability ?? .unavailable
                }
            )
        } else {
            self.eventPersistenceService = EventPersistenceService(
                repository: UnavailableEventRepository(),
                catalog: catalog,
                notificationService: notificationService,
                storageAvailability: .unavailable
            )

            let universeRepository = UnavailableUniverseMessageRepository()
            self.universeMessageRepository = universeRepository
            let universeEngine = UniverseMessageEngine(repository: universeRepository)
            self.universeMessageEngine = universeEngine
            self.universeMessageService = UniverseMessageService(
                repository: universeRepository,
                engine: universeEngine,
                storageAvailabilityProvider: { [weak self] in
                    self?.storageAvailability ?? .unavailable
                }
            )

            self.eventTemplateService = EventTemplateService(
                repository: UnavailableEventTemplateRepository(),
                storageAvailabilityProvider: { [weak self] in
                    self?.storageAvailability ?? .unavailable
                }
            )
        }
    }

    // MARK: - Recovery (manual / tests)

    /// Marks storage as recovering, then available or unavailable again.
    ///
    /// Does **not** automatically reopen SwiftData — CloudKit/backup recovery
    /// stays out of scope. Used by tests and a future explicit retry UI.
    func applyStorageAvailability(_ availability: StorageAvailability) {
        storageAvailability = availability
        eventPersistenceService.updateStorageAvailability(availability)
        switch availability {
        case .available:
            persistenceLaunchError = nil
        case .unavailable, .recovering:
            persistenceLaunchError = .storeUnavailable
        }
    }
}

//
//  DependencyContainer.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// Composition Root: single owner of app-scoped dependencies.
///
/// # Role
/// Created **once** at launch (`GalacticCalendarApp`) and injected via
/// `@Environment(DependencyContainer.self)`. All long-lived services and
/// repositories are constructed here — Views must not open SwiftData stores
/// or instantiate Infrastructure types directly (previews/tests excepted).
///
/// # What Presentation receives
/// | Surface | Type | Notes |
/// |---|---|---|
/// | `eventPersistenceService` | `EventPersistenceService` | Application façade (Environment) |
/// | `eventTemplateService` | `EventTemplateService` | Application façade (Environment) |
/// | `themeManager` / `calendarAppearanceManager` | Application | Environment |
/// | `appConfiguration` | Application | Environment |
/// | Screen VMs | via ``ViewModelFactory`` | Home, grid, Universe card |
/// | Universe child VMs | Domain **protocols** via factory closures | No concrete repo types |
///
/// Concrete `EventRepository` / `EventTemplateRepository` /
/// `NotificationRepository` are **not** stored as public properties —
/// they are wired into Application façades and discarded from the public graph.
/// `NotificationService` stays **private** (forwarded into persistence).
///
/// # Lifecycle
/// Process-scoped. Child ViewModels share these instances. Do not create a
/// second container in production UI.
///
/// # Reserved (not Environment-injected)
/// `navigationManager` / `appRouter` remain owned here for a future push stack
/// (QA-06). They are **not** placed in the Environment until product navigation
/// uses them.
@MainActor
@Observable
final class DependencyContainer {

    // MARK: - Configuration

    /// Application configuration façade.
    let appConfiguration: AppConfiguration

    // MARK: - Navigation (reserved — not Environment-injected)

    /// Navigation stack owner (future push / deep link).
    let navigationManager: NavigationManager

    /// High-level navigation coordinator (future typed routes).
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

    /// Catalog repository (protocol surface for Universe ViewModels via factory).
    let universeMessageRepository: any UniverseMessageRepositoryProtocol

    /// Day-selection engine (app-scoped; shared with Home / Universe card).
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

        // Explicit Composition Root collaborators for EventPersistenceService.
        let catalog = EventCatalogService()
        let validation = EventValidationService()

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

        let availabilityProvider: () -> StorageAvailability = { [weak self] in
            self?.storageAvailability ?? .unavailable
        }

        if let openedContainer {
            let eventRepository = EventRepository(modelContext: openedContainer.mainContext)
            self.eventPersistenceService = EventPersistenceService(
                repository: eventRepository,
                catalog: catalog,
                validationService: validation,
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
                storageAvailabilityProvider: availabilityProvider
            )

            let templateRepository = EventTemplateRepository(
                modelContext: openedContainer.mainContext
            )
            self.eventTemplateService = EventTemplateService(
                repository: templateRepository,
                storageAvailabilityProvider: availabilityProvider
            )
        } else {
            self.eventPersistenceService = EventPersistenceService(
                repository: UnavailableEventRepository(),
                catalog: catalog,
                validationService: validation,
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
                storageAvailabilityProvider: availabilityProvider
            )

            self.eventTemplateService = EventTemplateService(
                repository: UnavailableEventTemplateRepository(),
                storageAvailabilityProvider: availabilityProvider
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

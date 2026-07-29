//
//  EventPersistenceService.swift
//  GalacticCalendar
//

import Foundation

/// Errors produced by ``EventPersistenceService``.
enum EventPersistenceError: Error, Equatable, Sendable {

    // MARK: - Cases

    /// Domain validation failed before persistence.
    case validationFailed([EventValidationIssue])

    /// Underlying repository reported a missing event.
    case notFound(UUID)

    /// Underlying repository failed to save.
    case saveFailed

    /// Local reminder could not be scheduled because authorization was denied.
    case reminderUnauthorized

    /// Local reminder scheduling failed.
    case reminderSchedulingFailed

    /// Reminder fire date was rejected as not in the future.
    case reminderFireDateInPast

    /// Unexpected persistence failure.
    case unknown
}

/// Application façade for event write operations and catalog publication.
///
/// ## Responsibilities
/// - Validate before create/update.
/// - Persist through ``EventRepositoryProtocol``.
/// - Synchronize local reminders through ``NotificationService``.
/// - Publish results into ``EventCatalogService`` (SSOT for reads).
///
/// ## Non-responsibilities
/// - Catalog query algorithms live in ``EventCatalogService``.
/// - Validation rules live in ``EventValidationService``.
///
/// ## Observation
/// ``events`` / ``eventsRevision`` mirror the catalog so existing ViewModels keep observing this type.
@MainActor
@Observable
final class EventPersistenceService {

    // MARK: - Dependencies

    /// Imperative SwiftData (or future CloudKit) repository.
    private let repository: any EventRepositoryProtocol

    /// In-memory reactive catalog (read SSOT).
    private let catalog: EventCatalogService

    /// Validator applied before create/update.
    private let validationService: EventValidationService

    /// Schedules and cancels local event reminders after successful mutations.
    private let notificationService: NotificationService?

    // MARK: - Published Catalog Mirror

    /// In-memory event catalog mirrored from ``EventCatalogService``.
    private(set) var events: [Event] = []

    /// Monotonic token mirrored from ``EventCatalogService``.
    private(set) var eventsRevision: Int = 0

    // MARK: - Lifecycle

    /// Creates a persistence service.
    /// - Parameters:
    ///   - repository: Event repository implementation.
    ///   - catalog: In-memory catalog service.
    ///   - validationService: Event validator.
    ///   - notificationService: Optional reminder synchronizer.
    init(
        repository: any EventRepositoryProtocol,
        catalog: EventCatalogService = EventCatalogService(),
        validationService: EventValidationService = EventValidationService(),
        notificationService: NotificationService? = nil
    ) {
        self.repository = repository
        self.catalog = catalog
        self.validationService = validationService
        self.notificationService = notificationService
        publishCatalog()
    }

    // MARK: - Notifications

    /// Requests local-notification permission when still undetermined.
    /// - Returns: `true` when notifications may be delivered.
    @discardableResult
    func requestNotificationAuthorizationIfNeeded() async -> Bool {
        guard let notificationService else {
            return false
        }
        return await notificationService.requestAuthorizationIfNeeded()
    }

    // MARK: - Bootstrap

    /// Loads the catalog from the underlying repository.
    ///
    /// Call once at app start (Composition Root / root scene) so observers have data.
    func bootstrap() async {
        await refresh()
    }

    /// Reloads the catalog from the repository and publishes to observers.
    ///
    /// Load failures keep the last known catalog; mutating APIs surface errors.
    func refresh() async {
        do {
            let fetched = try await repository.fetchAll()
            catalog.replaceAll(with: fetched)
            publishCatalog()
        } catch {
            // Keep the last known catalog; surface errors on the next mutating call.
        }
    }

    // MARK: - Catalog Queries (sync, reactive)

    /// Returns catalog events occurring on the given calendar day, sorted by time.
    func events(on date: Date) -> [Event] {
        catalog.events(on: date)
    }

    /// Returns a catalog event by identifier.
    func event(id: UUID) -> Event? {
        catalog.event(id: id)
    }

    /// Groups catalog events by start-of-day for the given interval.
    func eventsGroupedByDay(in interval: DateInterval) -> [Date: [Event]] {
        catalog.eventsGroupedByDay(in: interval)
    }

    /// Returns catalog events whose ``RepeatRule`` is recurring.
    func recurringEvents() -> [Event] {
        catalog.recurringEvents()
    }

    // MARK: - Create

    /// Validates and creates an event, synchronizes its reminder, then refreshes the catalog.
    /// - Parameter event: Event to persist.
    func create(_ event: Event) async throws {
        try ensureValid(event)
        do {
            try await repository.create(event)
        } catch {
            throw mapError(error)
        }
        do {
            try await synchronizeReminder(for: event)
            await refresh()
        } catch {
            await refresh()
            throw mapError(error)
        }
    }

    // MARK: - Update

    /// Validates and updates an event, synchronizes its reminder, then refreshes the catalog.
    /// - Parameter event: Event to update.
    func update(_ event: Event) async throws {
        try ensureValid(event)
        do {
            try await repository.update(event)
        } catch {
            throw mapError(error)
        }
        do {
            try await synchronizeReminder(for: event)
            await refresh()
        } catch {
            await refresh()
            throw mapError(error)
        }
    }

    // MARK: - Delete

    /// Deletes an event, cancels its reminder, then refreshes the catalog.
    /// - Parameter event: Event to delete.
    func delete(_ event: Event) async throws {
        do {
            try await repository.delete(event)
        } catch {
            throw mapError(error)
        }
        do {
            try await cancelReminder(for: event.id)
            await refresh()
        } catch {
            await refresh()
            throw mapError(error)
        }
    }

    /// Deletes an event by identifier, cancels its reminder, then refreshes the catalog.
    /// - Parameter id: Event identifier.
    func delete(id: UUID) async throws {
        do {
            try await repository.delete(id: id)
        } catch {
            throw mapError(error)
        }
        do {
            try await cancelReminder(for: id)
            await refresh()
        } catch {
            await refresh()
            throw mapError(error)
        }
    }

    // MARK: - Duplicate

    /// Creates a persisted duplicate via ``create(_:)``.
    /// - Parameter event: Source event.
    /// - Returns: Newly created duplicate.
    @discardableResult
    func duplicate(_ event: Event) async throws -> Event {
        let copy = event.duplicated()
        try await create(copy)
        return copy
    }

    // MARK: - Private

    /// Mirrors catalog state onto this observable service.
    private func publishCatalog() {
        events = catalog.events
        eventsRevision = catalog.eventsRevision
    }

    /// Synchronizes the local reminder for a persisted event.
    private func synchronizeReminder(for event: Event) async throws {
        guard let notificationService else {
            return
        }
        try await notificationService.synchronizeReminder(for: event)
    }

    /// Cancels the local reminder for a deleted event.
    private func cancelReminder(for eventID: UUID) async throws {
        guard let notificationService else {
            return
        }
        try await notificationService.cancelReminder(for: eventID)
    }

    /// Ensures the event passes domain validation.
    private func ensureValid(_ event: Event) throws {
        let issues = validationService.validate(event)
        guard issues.isEmpty else {
            throw EventPersistenceError.validationFailed(issues)
        }
    }

    /// Maps repository and notification errors into persistence-service errors.
    private func mapError(_ error: Error) -> EventPersistenceError {
        if let persistenceError = error as? EventPersistenceError {
            return persistenceError
        }

        if let repositoryError = error as? EventRepositoryError {
            switch repositoryError {
            case .notFound(let id):
                return .notFound(id)
            case .saveFailed:
                return .saveFailed
            }
        }

        if let notificationError = error as? NotificationRepositoryError {
            switch notificationError {
            case .unauthorized:
                return .reminderUnauthorized
            case .schedulingFailed:
                return .reminderSchedulingFailed
            case .fireDateInPast:
                return .reminderFireDateInPast
            }
        }

        return .unknown
    }
}

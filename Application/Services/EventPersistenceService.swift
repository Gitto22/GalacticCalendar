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

    /// Catalog could not be loaded from the repository.
    case catalogLoadFailed

    /// Offline templates catalog could not be loaded.
    case templatesLoadFailed

    /// Persistent store could not be opened. Writes are blocked until storage is available again.
    case storeUnavailable

    /// Compensating rollback could not restore a consistent store/reminder/catalog state.
    case rollbackFailed

    /// Persisted data could not be decoded without inventing values.
    case dataCorruption

    /// Unexpected persistence failure.
    case unknown
}

/// Application façade for event write operations and catalog publication.
///
/// ## Responsibilities (PB-05.2)
/// - Gate writes on storage availability
/// - Validate → persist → refresh catalog (with compensating rollback)
/// - Publish an Observation mirror of ``EventCatalogService``
/// - Orchestrate quick mutations (duplicate / move / copy) against the store
///
/// ## Delegated (not owned)
/// - Domain validation → ``EventValidationService``
/// - Local reminders → ``EventReminderCoordinator``
/// - Occurrence→master schedule math → ``EventSchedule/resolvedMasterStart``
///
/// ## Atomicity
/// Mutations follow **persist → reminders → catalog refresh**.
/// If reminders or refresh fail after a write, the service rolls back the write
/// (create/update) so the store, reminders, and UI catalog stay aligned.
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

    /// Local reminder side effects (authorization / sync / cancel).
    private let reminderCoordinator: EventReminderCoordinator

    // MARK: - Storage Gate

    /// Global store availability. Writes require ``StorageAvailability/available``.
    private(set) var storageAvailability: StorageAvailability

    // MARK: - Published Catalog Mirror

    /// In-memory event catalog mirrored from ``EventCatalogService``.
    private(set) var events: [Event] = []

    /// Monotonic token mirrored from ``EventCatalogService``.
    private(set) var eventsRevision: Int = 0

    /// Last catalog load / refresh failure, if any.
    private(set) var lastError: EventPersistenceError?

    /// `true` when create / update / delete may run against a real store.
    var isWritable: Bool {
        storageAvailability.allowsWrites
    }

    // MARK: - Lifecycle

    /// Creates a persistence service.
    /// - Parameters:
    ///   - repository: Event repository implementation.
    ///   - catalog: In-memory catalog service.
    ///   - validationService: Event validator.
    ///   - notificationService: Optional reminder synchronizer (forwarded to ``EventReminderCoordinator``).
    ///   - storageAvailability: Initial store availability (defaults to writable).
    init(
        repository: any EventRepositoryProtocol,
        catalog: EventCatalogService = EventCatalogService(),
        validationService: EventValidationService = EventValidationService(),
        notificationService: NotificationService? = nil,
        storageAvailability: StorageAvailability = .available
    ) {
        self.repository = repository
        self.catalog = catalog
        self.validationService = validationService
        self.reminderCoordinator = EventReminderCoordinator(notificationService: notificationService)
        self.storageAvailability = storageAvailability
        if storageAvailability != .available {
            lastError = .storeUnavailable
        }
        publishCatalog()
    }

    // MARK: - Storage Availability

    /// Updates store availability (Composition Root / tests).
    ///
    /// When becoming ``unavailable`` / ``recovering``, sets ``lastError`` to
    /// ``EventPersistenceError/storeUnavailable``. When becoming ``available``,
    /// clears that specific error if it was the last recorded one.
    func updateStorageAvailability(_ availability: StorageAvailability) {
        storageAvailability = availability
        switch availability {
        case .available:
            if lastError == .storeUnavailable {
                lastError = nil
            }
            PersistenceLog.storageRecovery(succeeded: true)
        case .unavailable:
            lastError = .storeUnavailable
            PersistenceLog.storageUnavailableEntered()
        case .recovering:
            lastError = .storeUnavailable
        }
    }

    // MARK: - Notifications

    /// Requests local-notification permission when still undetermined.
    ///
    /// Public façade kept for ViewModels; implementation lives on ``EventReminderCoordinator``.
    /// - Returns: `true` when notifications may be delivered.
    /// - Throws: When the system authorization request fails.
    @discardableResult
    func requestNotificationAuthorizationIfNeeded() async throws -> Bool {
        try await reminderCoordinator.requestAuthorizationIfNeeded()
    }

    // MARK: - Catalog Reload

    /// Reloads the catalog from the repository and publishes to observers.
    ///
    /// Used for first load and after mutations. (Former `bootstrap()` alias removed in PB-05.3.)
    /// - Throws: ``EventPersistenceError/catalogLoadFailed`` when loading fails.
    func refresh() async throws {
        do {
            let fetched = try await repository.fetchAll()
            catalog.replaceAll(with: fetched)
            publishCatalog()
            if storageAvailability.allowsWrites {
                lastError = nil
            } else {
                lastError = .storeUnavailable
            }
        } catch {
            lastError = storageAvailability.allowsWrites ? .catalogLoadFailed : .storeUnavailable
            throw EventPersistenceError.catalogLoadFailed
        }
    }

    // MARK: - Catalog Queries (sync, reactive)

    /// Returns catalog events occurring on the given calendar day, sorted by time.
    func events(on date: Date) -> [Event] {
        catalog.events(on: date)
    }

    /// Returns catalog events on ``date`` matching ``criteria``.
    func events(on date: Date, matching criteria: EventSearchCriteria) -> [Event] {
        catalog.events(on: date, matching: criteria)
    }

    /// Returns master events matching ``criteria`` (single-pass catalog filter).
    func events(matching criteria: EventSearchCriteria) -> [Event] {
        _ = eventsRevision
        return catalog.events(matching: criteria)
    }

    /// Returns a catalog event by identifier.
    func event(id: UUID) -> Event? {
        catalog.event(id: id)
    }

    /// Groups catalog events by start-of-day for the given interval.
    func eventsGroupedByDay(in interval: DateInterval) -> [Date: [Event]] {
        catalog.eventsGroupedByDay(in: interval)
    }

    /// Groups catalog events by day after applying ``criteria``.
    func eventsGroupedByDay(
        in interval: DateInterval,
        matching criteria: EventSearchCriteria
    ) -> [Date: [Event]] {
        catalog.eventsGroupedByDay(in: interval, matching: criteria)
    }

    // MARK: - Create

    /// Validates, creates, synchronizes reminder, then refreshes the catalog.
    ///
    /// Rolls back the insert when reminder sync or catalog refresh fails.
    /// - Parameter event: Event to persist.
    func create(_ event: Event) async throws {
        try ensureWritable()
        try ensureValid(event)
        do {
            try await repository.create(event)
        } catch {
            throw mapError(error)
        }

        do {
            try await synchronizeReminder(for: event)
            try await refresh()
        } catch {
            let primary = mapError(error)
            do {
                try await rollbackCreatedEvent(id: event.id)
            } catch {
                throw EventPersistenceError.rollbackFailed
            }
            throw primary
        }
    }

    // MARK: - Update

    /// Validates, updates, synchronizes reminder, then refreshes the catalog.
    ///
    /// Restores the previous persisted snapshot when reminder sync or refresh fails.
    /// - Parameter event: Event to update.
    func update(_ event: Event) async throws {
        try ensureWritable()
        try ensureValid(event)

        let previous: Event
        do {
            guard let existing = try await repository.fetch(by: event.id) else {
                throw EventPersistenceError.notFound(event.id)
            }
            previous = existing
        } catch {
            throw mapError(error)
        }

        do {
            try await repository.update(event)
        } catch {
            throw mapError(error)
        }

        do {
            try await synchronizeReminder(for: event)
            try await refresh()
        } catch {
            let primary = mapError(error)
            do {
                try await rollbackUpdatedEvent(to: previous)
            } catch {
                throw EventPersistenceError.rollbackFailed
            }
            throw primary
        }
    }

    // MARK: - Delete

    /// Cancels reminder, deletes the event, then refreshes the catalog.
    ///
    /// Reminder cancellation runs first so a failed cancel does not remove the event.
    /// - Parameter event: Event to delete.
    func delete(_ event: Event) async throws {
        try await delete(id: event.id)
    }

    /// Cancels reminder, deletes by id, then refreshes the catalog.
    /// - Parameter id: Event identifier.
    func delete(id: UUID) async throws {
        try ensureWritable()
        do {
            try await cancelReminder(for: id)
        } catch {
            throw mapError(error)
        }

        do {
            try await repository.delete(id: id)
        } catch {
            throw mapError(error)
        }

        do {
            try await refresh()
        } catch {
            throw mapError(error)
        }
    }

    // MARK: - Duplicate / Move / Copy

    /// Creates a persisted duplicate via ``create(_:)`` (same schedule as source master).
    ///
    /// Resolves the persisted master so virtual recurrence occurrences are not
    /// treated as independent rows. Status resets to pending; reminder offset is preserved.
    /// - Parameter event: Source event (master or occurrence presentation).
    /// - Returns: Newly created duplicate.
    @discardableResult
    func duplicate(_ event: Event) async throws -> Event {
        try ensureWritable()
        let master = try await resolveMaster(for: event)
        let copy = master.duplicated()
        try await create(copy)
        return copy
    }

    /// Duplicates content onto a target calendar day (Quick Op / day-list Duplicate).
    ///
    /// Preserves wall-clock time (or all-day bounds) using ``EventSchedule/start(onDay:timeFrom:isAllDay:timeZoneIdentifier:)``.
    /// - Parameters:
    ///   - event: Source event (master or occurrence presentation).
    ///   - day: Calendar day that receives the new event.
    /// - Returns: Newly created duplicate.
    @discardableResult
    func duplicate(_ event: Event, onto day: Date) async throws -> Event {
        try ensureWritable()
        let master = try await resolveMaster(for: event)
        let start = EventSchedule.start(
            onDay: day,
            timeFrom: master.date,
            isAllDay: master.isAllDay,
            timeZoneIdentifier: master.timeZoneIdentifier
        )
        let copy = master.duplicated(on: start)
        try await create(copy)
        return copy
    }

    /// Moves / reprograms the persisted master to a new start (same identity).
    ///
    /// When ``event`` is a virtual occurrence, the series shifts by the day delta
    /// between the presented occurrence and ``newStart`` so the whole series moves
    /// relative to the tapped occurrence.
    /// - Parameters:
    ///   - event: Master or occurrence presentation from the day list.
    ///   - newStart: Absolute start after reprogramming (date ± time).
    /// - Returns: Updated master snapshot.
    @discardableResult
    func move(_ event: Event, to newStart: Date) async throws -> Event {
        try ensureWritable()
        let master = try await resolveMaster(for: event)
        let resolvedStart = EventSchedule.resolvedMasterStart(
            master: master,
            presented: event,
            targetStart: newStart
        )
        let moved = master.rescheduled(to: resolvedStart)
        try await update(moved)
        return moved
    }

    /// Creates a copy of the event on another date (new identity).
    ///
    /// Equivalent to ``duplicate(_:onto:)`` with an explicit absolute start when
    /// ``newStart`` already includes the desired wall-clock time.
    /// - Parameters:
    ///   - event: Source event (master or occurrence presentation).
    ///   - newStart: Absolute start for the copy.
    /// - Returns: Newly created event.
    @discardableResult
    func copy(_ event: Event, to newStart: Date) async throws -> Event {
        try ensureWritable()
        let master = try await resolveMaster(for: event)
        let copy = master.duplicated(on: newStart)
        try await create(copy)
        return copy
    }

    // MARK: - Private

    /// Loads the persisted master for mutations (ignores occurrence-shifted dates).
    private func resolveMaster(for event: Event) async throws -> Event {
        do {
            guard let master = try await repository.fetch(by: event.id) else {
                throw EventPersistenceError.notFound(event.id)
            }
            return master
        } catch {
            throw mapError(error)
        }
    }

    /// Mirrors catalog state onto this observable service.
    private func publishCatalog() {
        events = catalog.events
        eventsRevision = catalog.eventsRevision
    }

    /// Removes a created event and its reminder after a failed post-write step.
    ///
    /// Every step must succeed (or be a no-op `notFound`) so store, reminders,
    /// and catalog stay aligned. Failures set ``lastError`` and throw
    /// ``EventPersistenceError/rollbackFailed``.
    private func rollbackCreatedEvent(id: UUID) async throws {
        do {
            try await repository.delete(id: id)
        } catch let error as EventRepositoryError {
            if case .notFound = error {
                // Already absent — consistent with a rolled-back create.
            } else {
                lastError = mapError(error)
                throw EventPersistenceError.rollbackFailed
            }
        } catch {
            lastError = mapError(error)
            throw EventPersistenceError.rollbackFailed
        }

        do {
            try await cancelReminder(for: id)
        } catch {
            lastError = mapError(error)
            throw EventPersistenceError.rollbackFailed
        }

        do {
            try await refresh()
        } catch {
            throw EventPersistenceError.rollbackFailed
        }
    }

    /// Restores the previous event snapshot after a failed update pipeline.
    private func rollbackUpdatedEvent(to previous: Event) async throws {
        do {
            try await repository.update(previous)
        } catch {
            lastError = mapError(error)
            throw EventPersistenceError.rollbackFailed
        }

        do {
            try await synchronizeReminder(for: previous)
        } catch {
            lastError = mapError(error)
            throw EventPersistenceError.rollbackFailed
        }

        do {
            try await refresh()
        } catch {
            throw EventPersistenceError.rollbackFailed
        }
    }

    /// Synchronizes the local reminder for a persisted event.
    private func synchronizeReminder(for event: Event) async throws {
        try await reminderCoordinator.synchronize(for: event)
    }

    /// Cancels the local reminder for a deleted event.
    private func cancelReminder(for eventID: UUID) async throws {
        try await reminderCoordinator.cancel(for: eventID)
    }

    /// Ensures the event passes domain validation.
    private func ensureValid(_ event: Event) throws {
        let issues = validationService.validate(event)
        guard issues.isEmpty else {
            throw EventPersistenceError.validationFailed(issues)
        }
    }

    /// Refuses mutations when the on-disk store is not available.
    private func ensureWritable() throws {
        guard storageAvailability.allowsWrites else {
            PersistenceLog.writeBlocked(operation: "EventPersistenceService")
            lastError = .storeUnavailable
            throw EventPersistenceError.storeUnavailable
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
            case .corruptData:
                return .dataCorruption
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

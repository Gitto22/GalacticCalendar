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

    /// Unexpected persistence failure.
    case unknown
}

/// Reactive application façade for event persistence.
///
/// ## Single Source of Truth
/// ``events`` is the in-memory catalog observed by ViewModels.
/// Mutations write through ``EventRepositoryProtocol``, then refresh the catalog.
/// Presentation must read from this service (or ViewModels that derive from it),
/// not from ad-hoc repository fetches in views.
///
/// ## CloudKit
/// When remote changes arrive, call ``refresh()`` to realign the catalog
/// without introducing NotificationCenter fan-out.
@MainActor
@Observable
final class EventPersistenceService {

    // MARK: - Dependencies

    /// Imperative SwiftData (or future CloudKit) repository.
    private let repository: any EventRepositoryProtocol

    /// Validator applied before create/update.
    private let validationService: EventValidationService

    /// Calendar used for day-boundary queries against the catalog.
    private let calendar: Calendar

    // MARK: - Source of Truth

    /// In-memory event catalog. ViewModels observe this array for automatic UI sync.
    private(set) var events: [Event] = []

    /// Monotonic token advanced whenever ``events`` is replaced after a mutation or refresh.
    ///
    /// Kept for lightweight identity/`task(id:)` bridging; prefer observing ``events`` directly.
    private(set) var eventsRevision: Int = 0

    // MARK: - Lifecycle

    /// Creates a persistence service.
    /// - Parameters:
    ///   - repository: Event repository implementation.
    ///   - validationService: Event validator.
    ///   - calendar: Calendar for day queries.
    init(
        repository: any EventRepositoryProtocol,
        validationService: EventValidationService = EventValidationService(),
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.validationService = validationService
        self.calendar = calendar
    }

    // MARK: - Bootstrap

    /// Loads the catalog from the underlying repository.
    ///
    /// Call once at app start (Composition Root / root scene) so observers have data.
    func bootstrap() async {
        await refresh()
    }

    /// Reloads ``events`` from the repository and advances ``eventsRevision``.
    func refresh() async {
        do {
            let fetched = try await repository.fetchAll()
            replaceCatalog(with: fetched)
        } catch {
            // Keep the last known catalog; surface errors on the next mutating call.
        }
    }

    // MARK: - Catalog Queries (sync, reactive)

    /// Returns catalog events occurring on the given calendar day, sorted by time.
    /// - Parameter date: Day anchor.
    /// - Returns: Matching events from ``events``.
    func events(on date: Date) -> [Event] {
        let dayStart = calendar.startOfDay(for: date)
        return events
            .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
            .sorted { $0.date < $1.date }
    }

    /// Returns a catalog event by identifier.
    /// - Parameter id: Event identifier.
    /// - Returns: Matching event, if present in ``events``.
    func event(id: UUID) -> Event? {
        events.first { $0.id == id }
    }

    /// Groups catalog events by start-of-day for the given interval.
    /// - Parameter interval: Query interval (`end` exclusive).
    /// - Returns: Day-start keys mapped to events.
    func eventsGroupedByDay(in interval: DateInterval) -> [Date: [Event]] {
        let filtered = events.filter { event in
            event.date >= interval.start && event.date < interval.end
        }
        return Dictionary(grouping: filtered) { event in
            calendar.startOfDay(for: event.date)
        }
    }

    /// Returns catalog events whose ``RepeatRule`` is recurring.
    /// - Returns: Recurring events (occurrences are not expanded).
    func recurringEvents() -> [Event] {
        events.filter(\.repeatRule.isRecurring)
    }

    // MARK: - Create

    /// Validates and creates an event, then refreshes the catalog.
    /// - Parameter event: Event to persist.
    func create(_ event: Event) async throws {
        try ensureValid(event)
        do {
            try await repository.create(event)
            await refresh()
        } catch {
            throw mapRepositoryError(error)
        }
    }

    // MARK: - Read (async façade — prefers catalog)

    /// Returns all catalog events.
    func fetchAll() async throws -> [Event] {
        events
    }

    /// Returns a catalog event by identifier.
    /// - Parameter id: Event identifier.
    func fetch(by id: UUID) async throws -> Event? {
        event(id: id)
    }

    /// Returns catalog events for a specific calendar day.
    /// - Parameter date: Day anchor.
    func fetch(on date: Date) async throws -> [Event] {
        events(on: date)
    }

    /// Returns catalog events inside a date interval.
    /// - Parameter interval: Query interval.
    func fetch(in interval: DateInterval) async throws -> [Event] {
        events.filter { event in
            event.date >= interval.start && event.date < interval.end
        }
        .sorted { $0.date < $1.date }
    }

    /// Returns catalog events grouped by start-of-day.
    /// - Parameter interval: Query interval.
    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] {
        eventsGroupedByDay(in: interval)
    }

    /// Returns recurring catalog events.
    func fetchRecurring() async throws -> [Event] {
        recurringEvents()
    }

    // MARK: - Update

    /// Validates and updates an event, then refreshes the catalog.
    /// - Parameter event: Event to update.
    func update(_ event: Event) async throws {
        try ensureValid(event)
        do {
            try await repository.update(event)
            await refresh()
        } catch {
            throw mapRepositoryError(error)
        }
    }

    // MARK: - Delete

    /// Deletes an event, then refreshes the catalog.
    /// - Parameter event: Event to delete.
    func delete(_ event: Event) async throws {
        do {
            try await repository.delete(event)
            await refresh()
        } catch {
            throw mapRepositoryError(error)
        }
    }

    /// Deletes an event by identifier, then refreshes the catalog.
    /// - Parameter id: Event identifier.
    func delete(id: UUID) async throws {
        do {
            try await repository.delete(id: id)
            await refresh()
        } catch {
            throw mapRepositoryError(error)
        }
    }

    // MARK: - Duplicate

    /// Creates a persisted duplicate, then refreshes the catalog via ``create(_:)``.
    /// - Parameter event: Source event.
    /// - Returns: Newly created duplicate.
    @discardableResult
    func duplicate(_ event: Event) async throws -> Event {
        let copy = event.duplicated()
        try await create(copy)
        return copy
    }

    // MARK: - Private

    /// Replaces the catalog and advances the revision token.
    private func replaceCatalog(with newEvents: [Event]) {
        events = newEvents.sorted { $0.date < $1.date }
        eventsRevision += 1
    }

    /// Ensures the event passes domain validation.
    private func ensureValid(_ event: Event) throws {
        let issues = validationService.validate(event)
        guard issues.isEmpty else {
            throw EventPersistenceError.validationFailed(issues)
        }
    }

    /// Maps repository errors into persistence-service errors.
    private func mapRepositoryError(_ error: Error) -> EventPersistenceError {
        if let repositoryError = error as? EventRepositoryError {
            switch repositoryError {
            case .notFound(let id):
                return .notFound(id)
            case .saveFailed:
                return .saveFailed
            }
        }

        if let persistenceError = error as? EventPersistenceError {
            return persistenceError
        }

        return .unknown
    }
}

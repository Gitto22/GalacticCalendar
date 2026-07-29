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

/// Application entry point for event persistence used by ViewModels.
///
/// Validates domain events, then delegates to ``EventRepositoryProtocol``.
/// Contains no UI logic.
@MainActor
@Observable
final class EventPersistenceService {

    // MARK: - Properties

    /// Repository responsible for SwiftData operations.
    private let repository: any EventRepositoryProtocol

    /// Validator applied before create/update.
    private let validationService: EventValidationService

    /// Monotonic revision bumped after every successful create, update, or delete.
    ///
    /// Calendar UI observes this value to refresh event indicators automatically.
    private(set) var eventsRevision: Int = 0

    // MARK: - Lifecycle

    /// Creates a persistence service.
    /// - Parameters:
    ///   - repository: Event repository implementation.
    ///   - validationService: Event validator.
    init(
        repository: any EventRepositoryProtocol,
        validationService: EventValidationService = EventValidationService()
    ) {
        self.repository = repository
        self.validationService = validationService
    }

    // MARK: - Create

    /// Validates and creates an event.
    /// - Parameter event: Event to persist.
    func create(_ event: Event) async throws {
        try ensureValid(event)
        do {
            try await repository.create(event)
            bumpEventsRevision()
        } catch {
            throw mapRepositoryError(error)
        }
    }

    // MARK: - Read

    /// Returns all persisted events.
    func fetchAll() async throws -> [Event] {
        do {
            return try await repository.fetchAll()
        } catch {
            throw mapRepositoryError(error)
        }
    }

    /// Returns an event by identifier.
    /// - Parameter id: Event identifier.
    func fetch(by id: UUID) async throws -> Event? {
        do {
            return try await repository.fetch(by: id)
        } catch {
            throw mapRepositoryError(error)
        }
    }

    /// Returns events for a specific calendar day.
    /// - Parameter date: Day anchor.
    func fetch(on date: Date) async throws -> [Event] {
        do {
            return try await repository.fetch(on: date)
        } catch {
            throw mapRepositoryError(error)
        }
    }

    /// Returns events inside a date interval.
    /// - Parameter interval: Query interval.
    func fetch(in interval: DateInterval) async throws -> [Event] {
        do {
            return try await repository.fetch(in: interval)
        } catch {
            throw mapRepositoryError(error)
        }
    }

    /// Returns events inside a date interval grouped by start-of-day.
    /// - Parameter interval: Query interval.
    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] {
        do {
            return try await repository.fetchGroupedByDay(in: interval)
        } catch {
            throw mapRepositoryError(error)
        }
    }

    // MARK: - Update

    /// Validates and updates an event.
    /// - Parameter event: Event to update.
    func update(_ event: Event) async throws {
        try ensureValid(event)
        do {
            try await repository.update(event)
            bumpEventsRevision()
        } catch {
            throw mapRepositoryError(error)
        }
    }

    // MARK: - Delete

    /// Deletes an event.
    /// - Parameter event: Event to delete.
    func delete(_ event: Event) async throws {
        do {
            try await repository.delete(event)
            bumpEventsRevision()
        } catch {
            throw mapRepositoryError(error)
        }
    }

    /// Deletes an event by identifier.
    /// - Parameter id: Event identifier.
    func delete(id: UUID) async throws {
        do {
            try await repository.delete(id: id)
            bumpEventsRevision()
        } catch {
            throw mapRepositoryError(error)
        }
    }

    // MARK: - Duplicate

    /// Creates a persisted duplicate of an existing event.
    /// - Parameter event: Source event.
    /// - Returns: Newly created duplicate.
    @discardableResult
    func duplicate(_ event: Event) async throws -> Event {
        let copy = event.duplicated()
        try await create(copy)
        return copy
    }

    // MARK: - Private

    /// Advances ``eventsRevision`` so observers reload calendar indicators.
    private func bumpEventsRevision() {
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

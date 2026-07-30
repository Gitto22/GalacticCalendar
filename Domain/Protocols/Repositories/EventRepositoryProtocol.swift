//
//  EventRepositoryProtocol.swift
//  GalacticCalendar
//

import Foundation

/// Contract for creating, reading, updating, and deleting events.
///
/// Implementations (SwiftData, CloudKit, in-memory) live outside Domain.
/// This protocol is imperative; the reactive catalog for UI is published by
/// ``EventPersistenceService`` via ``EventCatalogService``.
protocol EventRepositoryProtocol: AnyObject {

    // MARK: - Create

    /// Persists a new event.
    /// - Parameter event: Event to create.
    func create(_ event: Event) async throws

    // MARK: - Read

    /// Returns every stored event.
    func fetchAll() async throws -> [Event]

    /// Returns a single event by identifier.
    /// - Parameter id: Event identifier.
    func fetch(by id: UUID) async throws -> Event?

    /// Returns events occurring on the provided calendar day.
    /// - Parameter date: Day used as the query anchor.
    func fetch(on date: Date) async throws -> [Event]

    /// Returns events in the provided date interval.
    /// - Parameter interval: Date interval to query.
    func fetch(in interval: DateInterval) async throws -> [Event]

    /// Returns events in `interval` grouped by start-of-day.
    /// - Parameter interval: Date interval to query.
    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]]

    /// Returns stored masters matching ``criteria`` (in-memory single pass after fetch).
    ///
    /// Does **not** expand recurrence for date facets — prefer
    /// ``EventCatalogService/events(matching:)`` for UI search. This exists so
    /// offline tooling / tests can filter the store without the catalog.
    func fetch(matching criteria: EventSearchCriteria) async throws -> [Event]

    // MARK: - Update

    /// Updates an existing event.
    /// - Parameter event: Event with updated values.
    func update(_ event: Event) async throws

    // MARK: - Delete

    /// Deletes the provided event.
    /// - Parameter event: Event to delete.
    func delete(_ event: Event) async throws

    /// Deletes an event by identifier.
    /// - Parameter id: Event identifier.
    func delete(id: UUID) async throws

    // MARK: - Duplicate

    /// Persists a duplicated copy of an existing event.
    /// - Parameter event: Source event to duplicate.
    /// - Returns: The newly created duplicate.
    func duplicate(_ event: Event) async throws -> Event
}

// MARK: - Default Search

extension EventRepositoryProtocol {

    /// Default store-side filter: ``fetchAll`` + single-pass ``EventSearchCriteria/filter(_:)``.
    ///
    /// Does not expand recurrence for date facets. UI search should use
    /// ``EventCatalogService/events(matching:)``.
    func fetch(matching criteria: EventSearchCriteria) async throws -> [Event] {
        let all = try await fetchAll()
        guard criteria.isEmpty == false else {
            return all
        }
        return criteria.filter(all)
    }
}

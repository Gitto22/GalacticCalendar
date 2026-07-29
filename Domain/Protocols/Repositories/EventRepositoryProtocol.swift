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

    /// Returns events whose ``RepeatRule`` is recurring.
    ///
    /// Does **not** expand occurrences — only filters stored rules.
    func fetchRecurring() async throws -> [Event]

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

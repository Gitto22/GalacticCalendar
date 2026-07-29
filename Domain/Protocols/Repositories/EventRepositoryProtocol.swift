//
//  EventRepositoryProtocol.swift
//  GalacticCalendar
//

import Foundation

/// Contract for creating, reading, updating, and deleting events.
///
/// Implementations (SwiftData, CloudKit, in-memory) live outside Domain.
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
}

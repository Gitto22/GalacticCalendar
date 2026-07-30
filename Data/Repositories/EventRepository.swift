//
//  EventRepository.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// SwiftData-backed imperative repository for ``Event``.
///
/// ## Role
/// Translates between Domain ``Event`` and ``EventEntity``.
/// This type is **not** the UI source of truth — ``EventPersistenceService``
/// publishes into ``EventCatalogService`` for ViewModels.
///
/// ## CloudKit
/// Keep enum fields as raw strings so the same entities remain sync-friendly.
@MainActor
final class EventRepository: EventRepositoryProtocol {

    // MARK: - Properties

    /// SwiftData model context used for local persistence.
    private let modelContext: ModelContext

    /// Calendar used when resolving day boundaries for queries.
    private let calendar: Calendar

    // MARK: - Lifecycle

    /// Creates a repository bound to a model context.
    /// - Parameters:
    ///   - modelContext: SwiftData context.
    ///   - calendar: Calendar for day-range queries.
    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    // MARK: - Create

    func create(_ event: Event) async throws {
        let entity = try EventEntityMapper.makeEntity(from: event)
        modelContext.insert(entity)
        try save()
    }

    // MARK: - Read

    func fetchAll() async throws -> [Event] {
        let descriptor = FetchDescriptor<EventEntity>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let entities = try modelContext.fetch(descriptor)
        return try entities.map(EventEntityMapper.makeDomain(from:))
    }

    func fetch(by id: UUID) async throws -> Event? {
        guard let entity = try fetchEntity(id: id) else {
            return nil
        }
        return try EventEntityMapper.makeDomain(from: entity)
    }

    func fetch(on date: Date) async throws -> [Event] {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return []
        }

        return try await fetch(in: DateInterval(start: start, end: end))
    }

    func fetch(in interval: DateInterval) async throws -> [Event] {
        let start = interval.start
        let end = interval.end

        let predicate = #Predicate<EventEntity> { entity in
            entity.date >= start && entity.date < end
        }

        let descriptor = FetchDescriptor<EventEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let entities = try modelContext.fetch(descriptor)
        return try entities.map(EventEntityMapper.makeDomain(from:))
    }

    /// Fetches events in `interval` grouped by start-of-day.
    /// - Parameter interval: Query interval.
    /// - Returns: Events keyed by ``Calendar/startOfDay(for:)``.
    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] {
        let events = try await fetch(in: interval)
        return Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.date)
        }
    }

    func fetch(matching criteria: EventSearchCriteria) async throws -> [Event] {
        let all = try await fetchAll()
        guard criteria.isEmpty == false else {
            return all
        }
        // Single pass after fetch; recurrence date expansion stays in the catalog.
        return criteria.filter(all)
    }

    // MARK: - Update

    func update(_ event: Event) async throws {
        guard let entity = try fetchEntity(id: event.id) else {
            throw EventRepositoryError.notFound(event.id)
        }

        try EventEntityMapper.apply(event.touchingUpdatedAt(), to: entity)
        try save()
    }

    // MARK: - Delete

    func delete(_ event: Event) async throws {
        try await delete(id: event.id)
    }

    func delete(id: UUID) async throws {
        guard let entity = try fetchEntity(id: id) else {
            throw EventRepositoryError.notFound(id)
        }

        modelContext.delete(entity)
        try save()
    }

    // MARK: - Duplicate

    func duplicate(_ event: Event) async throws -> Event {
        let copy = event.duplicated()
        try await create(copy)
        return copy
    }

    // MARK: - Private

    /// Fetches a persistence entity by identifier.
    private func fetchEntity(id: UUID) throws -> EventEntity? {
        let predicate = #Predicate<EventEntity> { entity in
            entity.id == id
        }
        var descriptor = FetchDescriptor<EventEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// Saves the model context.
    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw EventRepositoryError.saveFailed
        }
    }
}

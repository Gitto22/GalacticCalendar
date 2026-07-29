//
//  EventRepository.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// Errors produced by ``EventRepository``.
enum EventRepositoryError: Error, Equatable, Sendable {

    // MARK: - Cases

    /// No persistence entity exists for the requested identifier.
    case notFound(UUID)

    /// A save operation failed.
    case saveFailed
}

/// SwiftData-backed repository for ``Event``.
///
/// Translates between Domain ``Event`` and ``EventEntity``.
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
        let entity = EventEntityMapper.makeEntity(from: event)
        modelContext.insert(entity)
        try save()
    }

    // MARK: - Read

    func fetchAll() async throws -> [Event] {
        let descriptor = FetchDescriptor<EventEntity>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map(EventEntityMapper.makeDomain(from:))
    }

    func fetch(by id: UUID) async throws -> Event? {
        try fetchEntity(id: id).map(EventEntityMapper.makeDomain(from:))
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
        return entities.map(EventEntityMapper.makeDomain(from:))
    }

    // MARK: - Update

    func update(_ event: Event) async throws {
        guard let entity = try fetchEntity(id: event.id) else {
            throw EventRepositoryError.notFound(event.id)
        }

        EventEntityMapper.apply(event.touchingUpdatedAt(), to: entity)
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

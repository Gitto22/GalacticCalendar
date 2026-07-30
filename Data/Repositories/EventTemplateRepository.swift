//
//  EventTemplateRepository.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// SwiftData-backed repository for ``EventTemplate`` (offline-first).
@MainActor
final class EventTemplateRepository: EventTemplateRepositoryProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(_ template: EventTemplate) async throws {
        modelContext.insert(try EventTemplateEntityMapper.makeEntity(from: template))
        try save()
    }

    func fetchAll() async throws -> [EventTemplate] {
        let descriptor = FetchDescriptor<EventTemplateEntity>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        let entities = try modelContext.fetch(descriptor)
        return CatalogResilientDecoder.decodeAll(
            entities,
            entityType: "EventTemplateEntity",
            id: \.id,
            decode: EventTemplateEntityMapper.makeDomain(from:)
        ).values
    }

    func fetch(by id: UUID) async throws -> EventTemplate? {
        guard let entity = try fetchEntity(id: id) else {
            return nil
        }
        return try EventTemplateEntityMapper.makeDomain(from: entity)
    }

    func update(_ template: EventTemplate) async throws {
        guard let entity = try fetchEntity(id: template.id) else {
            throw EventTemplateRepositoryError.notFound(template.id)
        }
        try EventTemplateEntityMapper.apply(template.touchingUpdatedAt(), to: entity)
        try save()
    }

    func delete(_ template: EventTemplate) async throws {
        try await delete(id: template.id)
    }

    func delete(id: UUID) async throws {
        guard let entity = try fetchEntity(id: id) else {
            throw EventTemplateRepositoryError.notFound(id)
        }
        modelContext.delete(entity)
        try save()
    }

    func duplicate(_ template: EventTemplate) async throws -> EventTemplate {
        let copy = template.duplicated(name: String(localized: "event_template_copy_suffix"))
        try await create(copy)
        return copy
    }

    private func fetchEntity(id: UUID) throws -> EventTemplateEntity? {
        let predicate = #Predicate<EventTemplateEntity> { $0.id == id }
        var descriptor = FetchDescriptor<EventTemplateEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw EventTemplateRepositoryError.saveFailed
        }
    }
}

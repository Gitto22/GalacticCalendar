//
//  EventTemplateRepositoryProtocol.swift
//  GalacticCalendar
//

import Foundation

/// Errors produced by event-template repositories.
enum EventTemplateRepositoryError: Error, Equatable, Sendable {

    case notFound(UUID)
    case saveFailed
    case corruptData
}

/// Imperative CRUD contract for ``EventTemplate`` (offline SwiftData / in-memory).
protocol EventTemplateRepositoryProtocol: AnyObject {

    func create(_ template: EventTemplate) async throws

    func fetchAll() async throws -> [EventTemplate]

    func fetch(by id: UUID) async throws -> EventTemplate?

    func update(_ template: EventTemplate) async throws

    func delete(_ template: EventTemplate) async throws

    func delete(id: UUID) async throws

    func duplicate(_ template: EventTemplate) async throws -> EventTemplate
}

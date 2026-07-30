//
//  SwiftDataIntegrationHarness.swift
//  GalacticCalendar
//
//  QA-02 — isolated SwiftData containers for integration tests.
//

import Foundation
import SwiftData
@testable import GalacticCalendar

/// Builds isolated SwiftData stores for integration tests (in-memory or on-disk).
@MainActor
enum SwiftDataIntegrationHarness {

    // MARK: - Containers

    /// Opens a unique in-memory store using the production schema + migration plan.
    static func makeInMemoryContainer() throws -> ModelContainer {
        try makeContainer(isStoredInMemoryOnly: true, storeURL: nil)
    }

    /// Opens a unique on-disk store under a fresh temporary directory.
    /// - Returns: Container and the directory to delete in `tearDown`.
    static func makeOnDiskContainer() throws -> (container: ModelContainer, directory: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GC-Integration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("GalacticCalendar.store")
        let container = try makeContainer(isStoredInMemoryOnly: false, storeURL: storeURL)
        return (container, directory)
    }

    /// Reopens an existing on-disk store at ``storeDirectory``.
    static func reopenOnDiskContainer(at storeDirectory: URL) throws -> ModelContainer {
        let storeURL = storeDirectory.appendingPathComponent("GalacticCalendar.store")
        return try makeContainer(isStoredInMemoryOnly: false, storeURL: storeURL)
    }

    /// Removes a temporary store directory (best-effort).
    static func removeStoreDirectory(_ directory: URL?) {
        guard let directory else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Corrupt fixtures

    /// Inserts a deliberately undecodable event row (invalid color raw value).
    static func insertCorruptEventEntity(
        into context: ModelContext,
        id: UUID = UUID(),
        title: String = "Corrupt",
        date: Date = Date(timeIntervalSince1970: 1_900_000_000)
    ) throws {
        let entity = EventEntity(
            id: id,
            title: title,
            eventDescription: "",
            date: date,
            endDate: nil,
            isAllDay: false,
            timeZoneIdentifier: "UTC",
            reminder: nil,
            repeatRuleRawValue: "none",
            categoryRawValue: EventCategory.personal.rawValue,
            priorityRawValue: EventPriority.normal.rawValue,
            statusRawValue: EventStatus.pending.rawValue,
            colorRawValue: "__invalid_color__",
            tagsRawValue: "[]",
            createdAt: date,
            updatedAt: date
        )
        context.insert(entity)
        try context.save()
    }

    /// Inserts a deliberately undecodable template row.
    static func insertCorruptTemplateEntity(
        into context: ModelContext,
        id: UUID = UUID(),
        name: String = "Corrupt Template"
    ) throws {
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        let entity = EventTemplateEntity(
            id: id,
            name: name,
            title: "Broken",
            eventDescription: "",
            isAllDay: false,
            durationSeconds: 3_600,
            repeatRuleRawValue: "none",
            categoryRawValue: EventCategory.personal.rawValue,
            tagsRawValue: "[]",
            priorityRawValue: EventPriority.normal.rawValue,
            statusRawValue: EventStatus.pending.rawValue,
            colorRawValue: "__invalid_color__",
            timeZoneIdentifier: "UTC",
            createdAt: now,
            updatedAt: now
        )
        context.insert(entity)
        try context.save()
    }

    /// Materializes a domain ``Event`` from a template schedule (no ViewModel).
    static func makeEvent(
        from template: EventTemplate,
        startingAt start: Date = Date(timeIntervalSince1970: 1_900_000_000)
    ) -> Event {
        let bounds = template.scheduleBounds(on: start, timeZoneIdentifier: "UTC")
        return Event(
            title: template.title,
            description: template.description,
            date: bounds.date,
            endDate: bounds.endDate,
            isAllDay: template.isAllDay,
            timeZoneIdentifier: template.timeZoneIdentifier ?? "UTC",
            reminder: nil,
            repeatRule: template.repeatRule,
            category: template.category,
            tags: template.tags,
            priority: template.priority,
            status: template.status,
            color: template.color
        )
    }

    // MARK: - Private

    private static func makeContainer(
        isStoredInMemoryOnly: Bool,
        storeURL: URL?
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: GalacticCalendarSchemaV6.self)
        let configuration: ModelConfiguration
        if let storeURL {
            configuration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(
                "GalacticCalendar-Integration-\(UUID().uuidString)",
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(
            for: schema,
            migrationPlan: GalacticCalendarMigrationPlan.self,
            configurations: [configuration]
        )
    }
}

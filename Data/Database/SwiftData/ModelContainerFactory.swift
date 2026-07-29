//
//  ModelContainerFactory.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// Factory for constructing the SwiftData model container.
///
/// Local persistence first. CloudKit can be enabled later through
/// ``ModelConfiguration/cloudKitDatabase`` without changing Domain models.
enum ModelContainerFactory {

    // MARK: - Factory

    /// Creates the application model container.
    /// - Parameters:
    ///   - inMemory: When `true`, uses an in-memory store (tests / previews).
    ///   - enableCloudKit: When `true`, mirrors the store to CloudKit.
    /// - Returns: Configured ``ModelContainer``.
    static func make(
        inMemory: Bool = false,
        enableCloudKit: Bool = false
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: GalacticCalendarSchemaV1.self)
        let configuration = ModelConfiguration(
            "GalacticCalendar",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: enableCloudKit ? .automatic : .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: GalacticCalendarMigrationPlan.self,
            configurations: [configuration]
        )
    }
}

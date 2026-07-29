//
//  SchemaVersioning.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// Initial SwiftData schema for Galactic Calendar.
///
/// Versioned to support future CloudKit-ready migrations.
enum GalacticCalendarSchemaV1: VersionedSchema {

    // MARK: - VersionedSchema

    /// Schema version identifier.
    static var versionIdentifier = Schema.Version(1, 0, 0)

    /// Models included in this schema version.
    static var models: [any PersistentModel.Type] {
        [EventEntity.self]
    }
}

/// Migration plan prepared for future schema evolution / CloudKit enablement.
enum GalacticCalendarMigrationPlan: SchemaMigrationPlan {

    // MARK: - SchemaMigrationPlan

    /// Ordered schemas known to the migration plan.
    static var schemas: [any VersionedSchema.Type] {
        [GalacticCalendarSchemaV1.self]
    }

    /// Migration stages. Empty while only V1 exists.
    static var stages: [MigrationStage] {
        []
    }
}

//
//  SchemaVersioning.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// Initial SwiftData schema for Galactic Calendar (events only).
enum GalacticCalendarSchemaV1: VersionedSchema {

    // MARK: - VersionedSchema

    /// Schema version identifier.
    static var versionIdentifier = Schema.Version(1, 0, 0)

    /// Models included in this schema version.
    static var models: [any PersistentModel.Type] {
        [EventEntity.self]
    }
}

/// Schema adding Universe Messages catalog persistence.
enum GalacticCalendarSchemaV2: VersionedSchema {

    // MARK: - VersionedSchema

    /// Schema version identifier.
    static var versionIdentifier = Schema.Version(2, 0, 0)

    /// Models included in this schema version.
    static var models: [any PersistentModel.Type] {
        [EventEntity.self, UniverseMessageEntity.self]
    }
}

/// Schema adding Universe Message display history.
enum GalacticCalendarSchemaV3: VersionedSchema {

    // MARK: - VersionedSchema

    /// Schema version identifier.
    static var versionIdentifier = Schema.Version(3, 0, 0)

    /// Models included in this schema version.
    static var models: [any PersistentModel.Type] {
        [EventEntity.self, UniverseMessageEntity.self, UniverseMessageHistoryEntity.self]
    }
}

/// Schema adding all-day support on ``EventEntity``.
enum GalacticCalendarSchemaV4: VersionedSchema {

    // MARK: - VersionedSchema

    /// Schema version identifier.
    static var versionIdentifier = Schema.Version(4, 0, 0)

    /// Models included in this schema version.
    static var models: [any PersistentModel.Type] {
        [EventEntity.self, UniverseMessageEntity.self, UniverseMessageHistoryEntity.self]
    }
}

/// Schema adding event tags on ``EventEntity``.
enum GalacticCalendarSchemaV5: VersionedSchema {

    // MARK: - VersionedSchema

    /// Schema version identifier.
    static var versionIdentifier = Schema.Version(5, 0, 0)

    /// Models included in this schema version.
    static var models: [any PersistentModel.Type] {
        [EventEntity.self, UniverseMessageEntity.self, UniverseMessageHistoryEntity.self]
    }
}

/// Schema adding offline event templates.
enum GalacticCalendarSchemaV6: VersionedSchema {

    // MARK: - VersionedSchema

    static var versionIdentifier = Schema.Version(6, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            EventEntity.self,
            UniverseMessageEntity.self,
            UniverseMessageHistoryEntity.self,
            EventTemplateEntity.self
        ]
    }
}

/// Migration plan prepared for schema evolution / CloudKit enablement.
enum GalacticCalendarMigrationPlan: SchemaMigrationPlan {

    // MARK: - SchemaMigrationPlan

    static var schemas: [any VersionedSchema.Type] {
        [
            GalacticCalendarSchemaV1.self,
            GalacticCalendarSchemaV2.self,
            GalacticCalendarSchemaV3.self,
            GalacticCalendarSchemaV4.self,
            GalacticCalendarSchemaV5.self,
            GalacticCalendarSchemaV6.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            MigrationStage.lightweight(
                fromVersion: GalacticCalendarSchemaV1.self,
                toVersion: GalacticCalendarSchemaV2.self
            ),
            MigrationStage.lightweight(
                fromVersion: GalacticCalendarSchemaV2.self,
                toVersion: GalacticCalendarSchemaV3.self
            ),
            MigrationStage.lightweight(
                fromVersion: GalacticCalendarSchemaV3.self,
                toVersion: GalacticCalendarSchemaV4.self
            ),
            MigrationStage.lightweight(
                fromVersion: GalacticCalendarSchemaV4.self,
                toVersion: GalacticCalendarSchemaV5.self
            ),
            MigrationStage.lightweight(
                fromVersion: GalacticCalendarSchemaV5.self,
                toVersion: GalacticCalendarSchemaV6.self
            )
        ]
    }
}

//
//  CatalogResilientDecoder.swift
//  GalacticCalendar
//
//  QA-03 — catalog load never fails because of a single bad row.
//

import Foundation

/// Result of a resilient catalog decode pass.
struct CatalogDecodeResult<Domain>: Sendable where Domain: Sendable {

    // MARK: - Properties

    /// Successfully decoded domain values (order preserved).
    let values: [Domain]

    /// Identifiers of rows that were isolated (skipped) due to decode failure.
    let skippedIDs: [UUID]
}

/// Decodes persistence rows for catalog loads without aborting on corruption.
///
/// ## Contract (QA-03)
/// - Log each undecodable row (with error).
/// - Isolate it from the in-memory catalog (do not invent domain values).
/// - Continue decoding remaining rows.
/// - Never throw / cancel the whole load because of one bad entity.
///
/// The on-disk row is left untouched (data model unchanged).
enum CatalogResilientDecoder {

    // MARK: - Decode

    /// Maps entities to domain values, skipping undecodable rows.
    /// - Parameters:
    ///   - entities: Persistence rows in fetch order.
    ///   - entityType: Log label (e.g. `EventEntity`).
    ///   - id: Extracts the stable row identifier.
    ///   - decode: Throws when the row cannot be mapped safely.
    /// - Returns: Decoded values plus skipped ids.
    static func decodeAll<Entity, Domain: Sendable>(
        _ entities: [Entity],
        entityType: String,
        id: (Entity) -> UUID,
        decode: (Entity) throws -> Domain
    ) -> CatalogDecodeResult<Domain> {
        var values: [Domain] = []
        var skippedIDs: [UUID] = []
        values.reserveCapacity(entities.count)

        for entity in entities {
            do {
                values.append(try decode(entity))
            } catch {
                let entityID = id(entity)
                skippedIDs.append(entityID)
                PersistenceLog.corruptEntitySkipped(
                    entityType: entityType,
                    id: entityID,
                    error: error
                )
            }
        }

        return CatalogDecodeResult(values: values, skippedIDs: skippedIDs)
    }
}

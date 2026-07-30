//
//  CatalogResilienceTests.swift
//  GalacticCalendar
//
//  QA-03 — catalog load isolates corrupt rows and never aborts.
//

import XCTest
@testable import GalacticCalendar

final class CatalogResilienceTests: XCTestCase {

    // MARK: - Fixtures

    private struct StubEntity: Sendable {
        let id: UUID
        let payload: String
    }

    private enum StubDecodeError: Error, Equatable {
        case invalidPayload
    }

    private func decode(_ entity: StubEntity) throws -> String {
        guard entity.payload != "CORRUPT" else {
            throw StubDecodeError.invalidPayload
        }
        return entity.payload
    }

    // MARK: - Decode all healthy

    func testAllHealthyRowsDecodeInOrder() {
        let a = UUID()
        let b = UUID()
        let entities = [
            StubEntity(id: a, payload: "one"),
            StubEntity(id: b, payload: "two")
        ]

        let result = CatalogResilientDecoder.decodeAll(
            entities,
            entityType: "StubEntity",
            id: \.id,
            decode: decode
        )

        XCTAssertEqual(result.values, ["one", "two"])
        XCTAssertTrue(result.skippedIDs.isEmpty)
    }

    // MARK: - Isolate corrupt

    func testCorruptRowIsIsolatedAndHealthyContinue() {
        let healthyID = UUID()
        let corruptID = UUID()
        let trailingID = UUID()
        let entities = [
            StubEntity(id: healthyID, payload: "ok-1"),
            StubEntity(id: corruptID, payload: "CORRUPT"),
            StubEntity(id: trailingID, payload: "ok-2")
        ]

        let result = CatalogResilientDecoder.decodeAll(
            entities,
            entityType: "StubEntity",
            id: \.id,
            decode: decode
        )

        XCTAssertEqual(result.values, ["ok-1", "ok-2"])
        XCTAssertEqual(result.skippedIDs, [corruptID])
        XCTAssertFalse(result.values.contains("CORRUPT"))
    }

    // MARK: - Never cancel load

    func testAllCorruptReturnsEmptyWithoutThrowing() {
        let entities = [
            StubEntity(id: UUID(), payload: "CORRUPT"),
            StubEntity(id: UUID(), payload: "CORRUPT")
        ]

        let result = CatalogResilientDecoder.decodeAll(
            entities,
            entityType: "StubEntity",
            id: \.id,
            decode: decode
        )

        XCTAssertTrue(result.values.isEmpty)
        XCTAssertEqual(result.skippedIDs.count, 2)
    }

    func testEmptyInputReturnsEmpty() {
        let result = CatalogResilientDecoder.decodeAll(
            [StubEntity](),
            entityType: "StubEntity",
            id: \.id,
            decode: decode
        )
        XCTAssertTrue(result.values.isEmpty)
        XCTAssertTrue(result.skippedIDs.isEmpty)
    }
}

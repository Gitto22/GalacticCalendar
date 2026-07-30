//
//  UniverseMessageFavoriteTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for favorite toggle, persistence, and history filtering.
@MainActor
final class UniverseMessageFavoriteTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private let messageA = UniverseMessage(
        id: "um_a",
        textKey: "universe_message_body",
        category: .motivation
    )
    private let messageB = UniverseMessage(
        id: "um_b",
        textKey: "universe_message_body_02",
        category: .calm
    )

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
    }

    // MARK: - Add / Remove Favorite

    func testToggleFavoriteAddsFavorite() async throws {
        let repository = InMemoryFavoriteRepository(
            catalog: [messageA, messageB]
        )
        let engine = UniverseMessageEngine(repository: repository, calendar: calendar)
        let service = UniverseMessageService(repository: repository, engine: engine)

        let updated = try await service.toggleFavorite(messageA)

        XCTAssertTrue(updated.isFavorite)
        XCTAssertTrue(try await service.isFavorite(messageA))
        XCTAssertEqual(try await service.favoriteMessages().map(\.id), ["um_a"])
    }

    func testToggleFavoriteRemovesFavorite() async throws {
        let repository = InMemoryFavoriteRepository(
            favoriteIDs: ["um_a"],
            catalog: [
                UniverseMessage(
                    id: "um_a",
                    textKey: "universe_message_body",
                    category: .motivation,
                    isFavorite: true
                ),
                messageB
            ]
        )
        let engine = UniverseMessageEngine(repository: repository, calendar: calendar)
        let service = UniverseMessageService(repository: repository, engine: engine)

        let updated = try await service.toggleFavorite(
            UniverseMessage(
                id: "um_a",
                textKey: "universe_message_body",
                category: .motivation,
                isFavorite: true
            )
        )

        XCTAssertFalse(updated.isFavorite)
        XCTAssertFalse(try await service.isFavorite(messageA))
        XCTAssertTrue(try await service.favoriteMessages().isEmpty)
    }

    // MARK: - Persistence

    func testFavoritePersistsAcrossServiceInstances() async throws {
        let repository = InMemoryFavoriteRepository(catalog: [messageA, messageB])
        let engine = UniverseMessageEngine(repository: repository, calendar: calendar)
        let firstService = UniverseMessageService(repository: repository, engine: engine)

        _ = try await firstService.toggleFavorite(messageA)

        let secondEngine = UniverseMessageEngine(repository: repository, calendar: calendar)
        let secondService = UniverseMessageService(repository: repository, engine: secondEngine)

        XCTAssertTrue(try await secondService.isFavorite(messageA))
        XCTAssertEqual(try await secondService.favoriteMessages().map(\.id), ["um_a"])
    }

    func testToggleUpdatesEngineCatalogCache() async throws {
        let repository = InMemoryFavoriteRepository(catalog: [messageA])
        let engine = UniverseMessageEngine(repository: repository, calendar: calendar)
        await engine.refreshIfNeeded()
        let service = UniverseMessageService(repository: repository, engine: engine)

        _ = try await service.toggleFavorite(messageA)

        XCTAssertEqual(engine.catalog.first(where: { $0.id == "um_a" })?.isFavorite, true)
    }

    // MARK: - History Filtering

    func testHistoryFavoriteFilterShowsOnlyFavorites() async {
        let dayA = calendar.startOfDay(for: date(2026, 7, 29))
        let dayB = calendar.startOfDay(for: date(2026, 7, 28))
        let history = [
            UniverseMessageHistoryEntry(
                dayStart: dayA,
                messageId: "um_a",
                textKey: "universe_message_body",
                category: .motivation,
                isFavorite: true
            ),
            UniverseMessageHistoryEntry(
                dayStart: dayB,
                messageId: "um_b",
                textKey: "universe_message_body_02",
                category: .calm,
                isFavorite: false
            )
        ]
        let repository = InMemoryFavoriteRepository(
            history: history,
            favoriteIDs: ["um_a"],
            catalog: [
                UniverseMessage(
                    id: "um_a",
                    textKey: "universe_message_body",
                    category: .motivation,
                    isFavorite: true
                ),
                messageB
            ]
        )
        let engine = UniverseMessageEngine(repository: repository, calendar: calendar)
        let service = UniverseMessageService(repository: repository, engine: engine)
        let viewModel = UniverseHistoryViewModel(
            repository: repository,
            favoriteService: service,
            calendar: calendar
        )

        await viewModel.load()
        viewModel.favoriteFilter = .favorites

        XCTAssertEqual(viewModel.displayedRows.map(\.messageId), ["um_a"])
    }

    func testHistoryToggleFavoriteUpdatesRowsImmediately() async {
        let dayA = calendar.startOfDay(for: date(2026, 7, 29))
        let history = [
            UniverseMessageHistoryEntry(
                dayStart: dayA,
                messageId: "um_a",
                textKey: "universe_message_body",
                category: .motivation,
                isFavorite: false
            )
        ]
        let repository = InMemoryFavoriteRepository(
            history: history,
            catalog: [messageA]
        )
        let engine = UniverseMessageEngine(repository: repository, calendar: calendar)
        let service = UniverseMessageService(repository: repository, engine: engine)
        let viewModel = UniverseHistoryViewModel(
            repository: repository,
            favoriteService: service,
            calendar: calendar
        )

        await viewModel.load()
        guard let row = viewModel.displayedRows.first else {
            return XCTFail("Expected a row")
        }

        await viewModel.toggleFavorite(for: row)

        XCTAssertEqual(viewModel.displayedRows.first?.isFavorite, true)

        viewModel.favoriteFilter = .favorites
        XCTAssertEqual(viewModel.displayedRows.count, 1)

        await viewModel.toggleFavorite(for: viewModel.displayedRows[0])
        XCTAssertTrue(viewModel.isFilterEmpty)
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }
}

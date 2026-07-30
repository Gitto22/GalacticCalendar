//
//  UniverseMessageDetailViewModelTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for Universe Message detail presentation.
@MainActor
final class UniverseMessageDetailViewModelTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
    }

    // MARK: - Initialization

    func testInitializationUsesContextSnapshot() {
        let day = date(2026, 7, 29)
        let context = UniverseMessageDetailContext(
            messageId: "um_001",
            dayStart: day,
            message: "Snapshot body",
            category: .gratitude,
            isFavorite: true
        )
        let viewModel = makeViewModel(context: context)

        XCTAssertEqual(viewModel.messageId, "um_001")
        XCTAssertEqual(viewModel.dayStart, calendar.startOfDay(for: day))
        XCTAssertEqual(viewModel.message, "Snapshot body")
        XCTAssertEqual(viewModel.category, .gratitude)
        XCTAssertTrue(viewModel.isFavorite)
        XCTAssertFalse(viewModel.didLoad)
        XCTAssertEqual(viewModel.categoryText, UniverseCategoryDisplayNames.displayName(for: .gratitude))
        XCTAssertFalse(viewModel.shareText.isEmpty)
    }

    // MARK: - Load

    func testLoadRefreshesMessageFromCatalog() async {
        let repository = InMemoryFavoriteRepository(
            catalog: [
                UniverseMessage(
                    id: "um_001",
                    textKey: "universe_message_body",
                    category: .motivation,
                    isFavorite: true
                )
            ]
        )
        let context = UniverseMessageDetailContext(
            messageId: "um_001",
            dayStart: date(2026, 7, 29),
            message: "Stale snapshot",
            category: .calm,
            isFavorite: false
        )
        let viewModel = makeViewModel(context: context, repository: repository)

        await viewModel.load()

        XCTAssertTrue(viewModel.didLoad)
        XCTAssertEqual(viewModel.category, .motivation)
        XCTAssertTrue(viewModel.isFavorite)
        XCTAssertNotEqual(viewModel.message, "Stale snapshot")
        XCTAssertFalse(viewModel.message.isEmpty)
    }

    func testLoadKeepsSnapshotWhenCatalogMisses() async {
        let repository = InMemoryFavoriteRepository(catalog: [])
        let context = UniverseMessageDetailContext(
            messageId: "missing",
            dayStart: date(2026, 7, 29),
            message: "Snapshot only",
            category: .success,
            isFavorite: false
        )
        let viewModel = makeViewModel(context: context, repository: repository)

        await viewModel.load()

        XCTAssertTrue(viewModel.didLoad)
        XCTAssertEqual(viewModel.message, "Snapshot only")
        XCTAssertEqual(viewModel.category, .success)
        XCTAssertFalse(viewModel.isFavorite)
    }

    // MARK: - Favorite

    func testToggleFavoriteChangesState() async {
        let repository = InMemoryFavoriteRepository(
            catalog: [
                UniverseMessage(
                    id: "um_001",
                    textKey: "universe_message_body",
                    category: .motivation,
                    isFavorite: false
                )
            ]
        )
        let context = UniverseMessageDetailContext(
            messageId: "um_001",
            dayStart: date(2026, 7, 29),
            message: "Body",
            category: .motivation,
            isFavorite: false
        )
        let viewModel = makeViewModel(context: context, repository: repository)

        await viewModel.toggleFavorite()

        XCTAssertTrue(viewModel.isFavorite)

        await viewModel.toggleFavorite()

        XCTAssertFalse(viewModel.isFavorite)
    }

    // MARK: - Helpers

    private func makeViewModel(
        context: UniverseMessageDetailContext,
        repository: InMemoryFavoriteRepository? = nil
    ) -> UniverseMessageDetailViewModel {
        let repo = repository ?? InMemoryFavoriteRepository(
            catalog: [
                UniverseMessage(
                    id: context.messageId,
                    textKey: "universe_message_body",
                    category: context.category ?? .motivation,
                    isFavorite: context.isFavorite
                )
            ]
        )
        let engine = UniverseMessageEngine(repository: repo, calendar: calendar)
        let service = UniverseMessageService(repository: repo, engine: engine)
        return UniverseMessageDetailViewModel(
            context: context,
            repository: repo,
            favoriteService: service,
            calendar: calendar
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }
}

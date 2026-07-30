//
//  StorageAvailabilityTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Sprint P0.2 — safe persistence: store-open failure, write blocking, recovery, error propagation.
@MainActor
final class StorageAvailabilityTests: XCTestCase {

    // MARK: - Store open / unavailable service

    func testUnavailableRepositoryBlocksWritesAndAllowsEmptyReads() async {
        let service = EventPersistenceService(
            repository: UnavailableEventRepository(),
            storageAvailability: .unavailable
        )

        XCTAssertEqual(service.storageAvailability, .unavailable)
        XCTAssertFalse(service.isWritable)
        XCTAssertEqual(service.lastError, .storeUnavailable)

        let event = Event(
            title: "Blocked",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .green
        )

        do {
            try await service.create(event)
            XCTFail("Expected storeUnavailable")
        } catch EventPersistenceError.storeUnavailable {
            XCTAssertTrue(service.events.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        do {
            try await service.refresh()
        } catch {
            XCTFail("Safe empty refresh should succeed: \(error)")
        }
        XCTAssertTrue(service.events.isEmpty)
    }

    func testUpdateDeleteAndQuickOpsBlockedWhenUnavailable() async {
        let seed = Event(
            title: "Seed",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .green
        )
        let service = EventPersistenceService(
            repository: InMemoryEventRepository(seed: [seed]),
            storageAvailability: .unavailable
        )

        do {
            try await service.update(seed)
            XCTFail("Expected storeUnavailable on update")
        } catch EventPersistenceError.storeUnavailable {
            // expected
        } catch {
            XCTFail("Unexpected: \(error)")
        }

        do {
            try await service.delete(id: seed.id)
            XCTFail("Expected storeUnavailable on delete")
        } catch EventPersistenceError.storeUnavailable {
            // expected
        } catch {
            XCTFail("Unexpected: \(error)")
        }

        do {
            try await service.duplicate(seed, onto: seed.date)
            XCTFail("Expected storeUnavailable on duplicate")
        } catch EventPersistenceError.storeUnavailable {
            // expected
        } catch {
            XCTFail("Unexpected: \(error)")
        }
    }

    // MARK: - Recovery

    func testRecoveringThenAvailableReEnablesWrites() async throws {
        let service = EventPersistenceService(
            repository: InMemoryEventRepository(),
            storageAvailability: .unavailable
        )

        service.updateStorageAvailability(.recovering)
        XCTAssertEqual(service.storageAvailability, .recovering)
        XCTAssertFalse(service.isWritable)

        do {
            try await service.create(
                Event(title: "During recovery", date: Date(), color: .green)
            )
            XCTFail("Expected storeUnavailable while recovering")
        } catch EventPersistenceError.storeUnavailable {
            // expected
        }

        service.updateStorageAvailability(.available)
        XCTAssertTrue(service.isWritable)
        XCTAssertNil(service.lastError)

        let event = Event(
            title: "After recovery",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .orange
        )
        try await service.create(event)
        XCTAssertEqual(service.events.map(\.id), [event.id])
    }

    // MARK: - Error propagation (Home)

    func testHomePropagatesStoreUnavailableAndDoesNotClearIt() async {
        let persistence = EventPersistenceService(
            repository: UnavailableEventRepository(),
            storageAvailability: .unavailable
        )
        let home = makeHomeViewModel(persistence: persistence)
        home.consumeLaunchError(.storeUnavailable)

        XCTAssertTrue(home.isStorageUnavailable)
        XCTAssertEqual(home.lastError, .storeUnavailable)
        XCTAssertEqual(
            home.errorAlertMessage,
            EventEditorDisplayNames.message(for: .storeUnavailable)
        )

        home.clearLastError()
        XCTAssertEqual(home.lastError, .storeUnavailable)

        let day = CalendarDay(
            id: "day",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            dayNumber: 1,
            membership: .currentMonth,
            isToday: false,
            eventCount: 0,
            eventColors: []
        )
        await home.selectDay(day)
        XCTAssertFalse(home.isPresentingEventEditor)
        XCTAssertEqual(home.lastError, .storeUnavailable)
    }

    func testDependencyContainerApplyStorageAvailabilityMirrorsService() {
        let container = DependencyContainer()
        // Production container may be available or unavailable depending on disk;
        // force unavailable then available for the gate contract.
        container.applyStorageAvailability(.unavailable)
        XCTAssertEqual(container.storageAvailability, .unavailable)
        XCTAssertEqual(container.persistenceLaunchError, .storeUnavailable)
        XCTAssertFalse(container.eventPersistenceService.isWritable)

        container.applyStorageAvailability(.available)
        XCTAssertEqual(container.storageAvailability, .available)
        XCTAssertNil(container.persistenceLaunchError)
        XCTAssertTrue(container.eventPersistenceService.isWritable)
    }

    // MARK: - Helpers

    private func makeHomeViewModel(persistence: EventPersistenceService) -> HomeViewModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let previewRepo = UnavailableUniverseMessageRepository()
        let universeEngine = UniverseMessageEngine(repository: previewRepo, calendar: calendar)
        let favoriteService = UniverseMessageService(
            repository: previewRepo,
            engine: universeEngine
        )
        return HomeViewModel(
            eventPersistenceService: persistence,
            universeMessageViewModel: UniverseMessageViewModel(
                engine: universeEngine,
                calendar: calendar,
                now: { Date(timeIntervalSince1970: 1_900_000_000) }
            ),
            makeUniverseHistoryViewModel: {
                UniverseHistoryViewModel(
                    repository: previewRepo,
                    favoriteService: favoriteService,
                    calendar: calendar
                )
            },
            makeUniverseMessageDetailViewModel: { context in
                UniverseMessageDetailViewModel(
                    context: context,
                    repository: previewRepo,
                    favoriteService: favoriteService,
                    calendar: calendar
                )
            }
        )
    }
}

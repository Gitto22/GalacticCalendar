//
//  CalendarContainerView.swift
//  GalacticCalendar
//

import SwiftUI

/// Thin host for ``CalendarGridView`` when a container wrapper is needed.
///
/// ``HomeView`` embeds ``CalendarGridView`` directly.
struct CalendarContainerView: View {

    // MARK: - Environment

    @Environment(EventPersistenceService.self) private var eventPersistenceService

    // MARK: - Properties

    private let engine: CalendarEngine

    // MARK: - Lifecycle

    init(engine: CalendarEngine = CalendarEngine()) {
        self.engine = engine
    }

    // MARK: - Body

    var body: some View {
        CalendarGridView(
            viewModel: CalendarGridViewModel(
                persistenceService: eventPersistenceService,
                engine: engine
            )
        )
        .padding(.horizontal, Spacing.pageHorizontal)
        .task {
            do {
                try await eventPersistenceService.bootstrap()
            } catch {
                // Failure recorded on EventPersistenceService.lastError.
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Calendar Container") {
    let persistence = EventPersistenceService(
        repository: PreviewContainerEventRepository()
    )

    ZStack {
        MonthBackgroundView()
        CalendarContainerView()
    }
    .environment(ThemeManager())
    .environment(persistence)
}

@MainActor
private final class PreviewContainerEventRepository: EventRepositoryProtocol {

    func create(_ event: Event) async throws {}

    func fetchAll() async throws -> [Event] { [] }

    func fetch(by id: UUID) async throws -> Event? { nil }

    func fetch(on date: Date) async throws -> [Event] { [] }

    func fetch(in interval: DateInterval) async throws -> [Event] { [] }

    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] { [:] }

    func fetchRecurring() async throws -> [Event] { [] }

    func update(_ event: Event) async throws {}

    func delete(_ event: Event) async throws {}

    func delete(id: UUID) async throws {}

    func duplicate(_ event: Event) async throws -> Event { event.duplicated() }
}
#endif

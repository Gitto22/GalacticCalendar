//
//  HomeView.swift
//  GalacticCalendar
//

import SwiftUI

/// Approved Home screen for Galactic Calendar.
///
/// Composes:
/// 1. ``MonthBackgroundView``
/// 2. ``HomeHeaderView``
/// 3. ``UniverseMessageCard``
/// 4. ``CalendarGridView``
///
/// Day tap routes to ``DayEventsView`` when events exist, otherwise to ``EventEditorView``.
struct HomeView: View {

    // MARK: - Properties

    /// ViewModel for Home interactions and modal presentation.
    @State private var viewModel: HomeViewModel

    /// Engine providing real days for the current month.
    private let calendarEngine: CalendarEngine

    // MARK: - Lifecycle

    /// Creates the Home screen.
    /// - Parameters:
    ///   - viewModel: Home presentation model wired by the Composition Root.
    ///   - calendarEngine: Calendar structure generator.
    init(
        viewModel: HomeViewModel,
        calendarEngine: CalendarEngine = CalendarEngine()
    ) {
        _viewModel = State(initialValue: viewModel)
        self.calendarEngine = calendarEngine
    }

    // MARK: - Body

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack(alignment: .top) {
            MonthBackgroundView()

            VStack(spacing: Spacing.sm) {
                HomeHeaderView()

                UniverseMessageCard()
                    .padding(.horizontal, Spacing.pageHorizontal)

                CalendarGridView(engine: calendarEngine) { day in
                    Task { await viewModel.selectDay(day) }
                }
                .padding(.horizontal, Spacing.pageHorizontal)

                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .contain)
        .fullScreenCover(
            isPresented: $viewModel.isPresentingDayEvents,
            onDismiss: {
                viewModel.dismissDayEvents()
            }
        ) {
            dayEventsCover(viewModel: viewModel)
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingEventEditor,
            onDismiss: {
                viewModel.dismissEventEditor()
            }
        ) {
            eventEditorCover(viewModel: viewModel)
        }
    }

    // MARK: - Day Events

    /// Modal host for ``DayEventsView``.
    @ViewBuilder
    private func dayEventsCover(viewModel: HomeViewModel) -> some View {
        if let dayEventsViewModel = viewModel.dayEventsViewModel {
            DayEventsView(viewModel: dayEventsViewModel) {
                viewModel.dismissDayEvents()
            }
        }
    }

    // MARK: - Event Editor

    /// Modal host for ``EventEditorView`` over the approved cosmic background.
    @ViewBuilder
    private func eventEditorCover(viewModel: HomeViewModel) -> some View {
        ZStack {
            MonthBackgroundView()

            if let editorViewModel = viewModel.eventEditorViewModel {
                EventEditorView(viewModel: editorViewModel) {
                    viewModel.dismissEventEditor()
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Home") {
    let persistence = EventPersistenceService(
        repository: PreviewHomeEventRepository()
    )

    HomeView(viewModel: HomeViewModel(eventPersistenceService: persistence))
        .environment(ThemeManager())
        .environment(persistence)
}

@MainActor
private final class PreviewHomeEventRepository: EventRepositoryProtocol {

    func create(_ event: Event) async throws {}

    func fetchAll() async throws -> [Event] { [] }

    func fetch(by id: UUID) async throws -> Event? { nil }

    func fetch(on date: Date) async throws -> [Event] { [] }

    func fetch(in interval: DateInterval) async throws -> [Event] { [] }

    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] { [:] }

    func update(_ event: Event) async throws {}

    func delete(_ event: Event) async throws {}

    func delete(id: UUID) async throws {}

    func duplicate(_ event: Event) async throws -> Event { event.duplicated() }
}
#endif

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
/// Day tap routes by event count:
/// 0 → create editor, 1 → edit editor, 2+ → day events list.
struct HomeView: View {

    // MARK: - Environment

    /// Used to refresh the Universe Message when returning to the app after midnight.
    @Environment(\.scenePhase) private var scenePhase

    /// Calendar appearance for month title / background sync on navigation.
    @Environment(CalendarAppearanceManager.self) private var calendarAppearance

    /// Honors system Reduce Motion for calendar period transitions.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Properties

    /// ViewModel for Home interactions and modal presentation.
    @State private var viewModel: HomeViewModel

    /// Grid ViewModel reading the reactive event catalog.
    @State private var calendarGridViewModel: CalendarGridViewModel

    /// Controls the catalog / launch failure alert.
    @State private var isShowingErrorAlert: Bool = false

    // MARK: - Lifecycle

    /// Creates the Home screen.
    /// - Parameters:
    ///   - viewModel: Home presentation model.
    ///   - calendarGridViewModel: Grid presentation model bound to the event catalog.
    init(
        viewModel: HomeViewModel,
        calendarGridViewModel: CalendarGridViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        _calendarGridViewModel = State(initialValue: calendarGridViewModel)
    }

    // MARK: - Body

    var body: some View {
        @Bindable var viewModel = viewModel
        @Bindable var calendarGridViewModel = calendarGridViewModel

        ZStack(alignment: .top) {
            MonthBackgroundView()

            VStack(spacing: Spacing.sm) {
                HomeHeaderView(
                    onMenuTap: {
                        viewModel.presentUniverseHistory()
                    },
                    onSearchTap: {
                        viewModel.presentEventSearch()
                    },
                    onAgendaTap: {
                        viewModel.presentSmartAgenda()
                    },
                    onPreviousMonth: {
                        animateCalendarPeriodChange {
                            viewModel.goToPreviousMonth(
                                calendarGridViewModel: calendarGridViewModel,
                                calendarAppearance: calendarAppearance
                            )
                        }
                    },
                    onNextMonth: {
                        animateCalendarPeriodChange {
                            viewModel.goToNextMonth(
                                calendarGridViewModel: calendarGridViewModel,
                                calendarAppearance: calendarAppearance
                            )
                        }
                    },
                    onMonthTitleTap: {
                        viewModel.presentMonthPicker(from: calendarGridViewModel)
                    },
                    onYearTap: {
                        viewModel.presentYearPicker(from: calendarGridViewModel)
                    },
                    onTodayTap: {
                        animateCalendarPeriodChange {
                            viewModel.goToToday(
                                calendarGridViewModel: calendarGridViewModel,
                                calendarAppearance: calendarAppearance
                            )
                        }
                    }
                )

                UniverseMessageCard(viewModel: viewModel.universeMessageViewModel) {
                    viewModel.presentUniverseMessageDetail()
                }
                    .padding(.horizontal, Spacing.pageHorizontal)

                CalendarGridView(
                    viewModel: calendarGridViewModel,
                    onDaySelected: { day in
                        Task { await viewModel.selectDay(day) }
                    },
                    onMonthNavigate: { intent in
                        animateCalendarPeriodChange(prefersAnimation: intent.prefersAnimation) {
                            viewModel.navigateMonth(
                                intent,
                                calendarGridViewModel: calendarGridViewModel,
                                calendarAppearance: calendarAppearance
                            )
                        }
                    }
                )
                .padding(.horizontal, Spacing.pageHorizontal)

                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home_screen")
        .onAppear {
            calendarGridViewModel.bindSearch(viewModel.eventSearchViewModel)
            viewModel.syncDisplayedMonth(
                from: calendarGridViewModel,
                calendarAppearance: calendarAppearance
            )
            if viewModel.lastError != nil {
                isShowingErrorAlert = true
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else {
                return
            }
            viewModel.universeMessageViewModel.refreshIfDayChanged()
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingUniverseHistory,
            onDismiss: {
                viewModel.dismissUniverseHistory()
                Task {
                    await viewModel.universeMessageViewModel.syncFavoriteState()
                }
            }
        ) {
            universeHistoryCover(viewModel: viewModel)
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingMonthPicker,
            onDismiss: {
                viewModel.dismissMonthPicker()
            }
        ) {
            monthPickerCover(
                viewModel: viewModel,
                calendarGridViewModel: calendarGridViewModel,
                calendarAppearance: calendarAppearance
            )
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingYearPicker,
            onDismiss: {
                viewModel.dismissYearPicker()
            }
        ) {
            yearPickerCover(
                viewModel: viewModel,
                calendarGridViewModel: calendarGridViewModel,
                calendarAppearance: calendarAppearance
            )
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingUniverseDetail,
            onDismiss: {
                viewModel.dismissUniverseMessageDetail()
                Task {
                    await viewModel.universeMessageViewModel.syncFavoriteState()
                }
            }
        ) {
            universeDetailCover(viewModel: viewModel)
        }
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
        .fullScreenCover(
            isPresented: $viewModel.isPresentingEventSearch,
            onDismiss: {
                viewModel.dismissEventSearch()
            }
        ) {
            EventSearchView(viewModel: viewModel.eventSearchViewModel) {
                viewModel.dismissEventSearch()
            }
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingSmartAgenda,
            onDismiss: {
                viewModel.dismissSmartAgenda()
            }
        ) {
            if let agenda = viewModel.smartAgendaViewModel {
                SmartAgendaView(viewModel: agenda) {
                    viewModel.dismissSmartAgenda()
                }
            }
        }
        .onChange(of: viewModel.lastError) { _, error in
            isShowingErrorAlert = error != nil
        }
        .alert(
            String(localized: "event_error_alert_title"),
            isPresented: $isShowingErrorAlert
        ) {
            if viewModel.isStorageUnavailable {
                Button(String(localized: "event_error_alert_dismiss"), role: .cancel) {
                    // Keep ``storeUnavailable`` on the ViewModel so writes stay blocked.
                    isShowingErrorAlert = false
                }
            } else {
                Button(String(localized: "event_error_alert_dismiss"), role: .cancel) {
                    viewModel.clearLastError()
                }
            }
        } message: {
            Text(viewModel.errorAlertMessage ?? String(localized: "event_error_unknown"))
        }
    }

    // MARK: - Motion

    /// Applies calendar period mutations inside a discreet ``Motion`` transaction.
    private func animateCalendarPeriodChange(
        prefersAnimation: Bool = true,
        _ updates: () -> Void
    ) {
        guard prefersAnimation,
              let animation = Motion.resolved(
                Motion.calendarMonthChange,
                reduceMotion: reduceMotion
              ) else {
            updates()
            return
        }
        withAnimation(animation, updates)
    }

    // MARK: - Month Picker

    /// Modal host for ``MonthPickerView``.
    @ViewBuilder
    private func monthPickerCover(
        viewModel: HomeViewModel,
        calendarGridViewModel: CalendarGridViewModel,
        calendarAppearance: CalendarAppearanceManager
    ) -> some View {
        if let pickerViewModel = viewModel.monthPickerViewModel {
            MonthPickerView(
                viewModel: pickerViewModel,
                onMonthSelected: { month in
                    animateCalendarPeriodChange {
                        viewModel.applyMonthPickerSelection(
                            month,
                            calendarGridViewModel: calendarGridViewModel,
                            calendarAppearance: calendarAppearance
                        )
                    }
                },
                onDismiss: {
                    viewModel.dismissMonthPicker()
                }
            )
        }
    }

    // MARK: - Year Picker

    /// Modal host for ``YearPickerView``.
    @ViewBuilder
    private func yearPickerCover(
        viewModel: HomeViewModel,
        calendarGridViewModel: CalendarGridViewModel,
        calendarAppearance: CalendarAppearanceManager
    ) -> some View {
        if let pickerViewModel = viewModel.yearPickerViewModel {
            YearPickerView(
                viewModel: pickerViewModel,
                onYearSelected: { year in
                    animateCalendarPeriodChange {
                        viewModel.applyYearPickerSelection(
                            year,
                            calendarGridViewModel: calendarGridViewModel,
                            calendarAppearance: calendarAppearance
                        )
                    }
                },
                onDismiss: {
                    viewModel.dismissYearPicker()
                }
            )
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

    // MARK: - Universe History

    /// Modal host for ``UniverseHistoryView``.
    @ViewBuilder
    private func universeHistoryCover(viewModel: HomeViewModel) -> some View {
        if let historyViewModel = viewModel.universeHistoryViewModel {
            UniverseHistoryView(viewModel: historyViewModel) {
                viewModel.dismissUniverseHistory()
            }
        }
    }

    // MARK: - Universe Detail

    /// Modal host for ``UniverseMessageDetailView`` opened from Home.
    @ViewBuilder
    private func universeDetailCover(viewModel: HomeViewModel) -> some View {
        if let detailViewModel = viewModel.universeDetailViewModel {
            UniverseMessageDetailView(viewModel: detailViewModel) {
                viewModel.dismissUniverseMessageDetail()
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
    let previewRepo = PreviewHomeUniverseMessageRepository()
    let universeEngine = UniverseMessageEngine(repository: previewRepo)
    let favoriteService = UniverseMessageService(
        repository: previewRepo,
        engine: universeEngine
    )

    HomeView(
        viewModel: HomeViewModel(
            eventPersistenceService: persistence,
            universeMessageViewModel: UniverseMessageViewModel(engine: universeEngine),
            makeUniverseHistoryViewModel: {
                UniverseHistoryViewModel(
                    repository: previewRepo,
                    favoriteService: favoriteService
                )
            },
            makeUniverseMessageDetailViewModel: { context in
                UniverseMessageDetailViewModel(
                    context: context,
                    repository: previewRepo,
                    favoriteService: favoriteService
                )
            }
        ),
        calendarGridViewModel: CalendarGridViewModel(persistenceService: persistence)
    )
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
    .environment(persistence)
}

@MainActor
private final class PreviewHomeUniverseMessageRepository: UniverseMessageRepositoryProtocol {

    private var favoriteIDs: Set<String> = []

    func fetchAll() async throws -> [UniverseMessage] {
        [
            UniverseMessage(
                id: "preview",
                textKey: "universe_message_body",
                category: .motivation,
                isFavorite: favoriteIDs.contains("preview")
            )
        ]
    }

    func fetch(by id: String) async throws -> UniverseMessage? {
        try await fetchAll().first { $0.id == id }
    }

    func ensureSeeded() async throws {}

    func fetchHistory() async throws -> [UniverseMessageHistoryEntry] { [] }

    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws {}

    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage {
        if favoriteIDs.contains(message.id) {
            favoriteIDs.remove(message.id)
        } else {
            favoriteIDs.insert(message.id)
        }
        return UniverseMessage(
            id: message.id,
            textKey: "universe_message_body",
            category: .motivation,
            isFavorite: favoriteIDs.contains(message.id)
        )
    }

    func favoriteMessages() async throws -> [UniverseMessage] {
        try await fetchAll().filter(\.isFavorite)
    }

    func isFavorite(_ message: UniverseMessage) async throws -> Bool {
        favoriteIDs.contains(message.id)
    }
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

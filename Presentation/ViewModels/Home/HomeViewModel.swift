//
//  HomeViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Presentation model for the Home screen.
///
/// Owns Home interaction state for day selection, day-events list,
/// event-editor presentation, Universe Message surfaces, month
/// step navigation, month/year pickers, and go-to-today
/// (title / background via ``CalendarAppearanceManager``).
@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Dependencies

    /// Persistence façade used to construct feature ViewModels.
    private let eventPersistenceService: EventPersistenceService

    /// Offline templates façade used by day-events / editor flows.
    private let eventTemplateService: EventTemplateService?

    /// Universe day-selection engine (shared with Agenda).
    private let universeMessageEngine: UniverseMessageEngine?

    // MARK: - State

    /// Universe Message card presentation model (Home integration).
    let universeMessageViewModel: UniverseMessageViewModel

    /// Shared incremental event search / filter state (Sprint 6.7).
    let eventSearchViewModel: EventSearchViewModel

    /// Factory used to build the history screen ViewModel on demand.
    private let makeUniverseHistoryViewModel: () -> UniverseHistoryViewModel

    /// Factory used to build the detail screen ViewModel on demand.
    private let makeUniverseMessageDetailViewModel: (UniverseMessageDetailContext) -> UniverseMessageDetailViewModel

    /// Absolute date of the currently selected calendar day, if any.
    private(set) var selectedDate: Date?

    /// `true` while the day-events list is presented.
    var isPresentingDayEvents: Bool = false

    /// ViewModel driving the day-events screen, if any.
    private(set) var dayEventsViewModel: DayEventsViewModel?

    /// `true` while the Universe history screen is presented.
    var isPresentingUniverseHistory: Bool = false

    /// ViewModel driving the Universe history screen, if any.
    private(set) var universeHistoryViewModel: UniverseHistoryViewModel?

    /// `true` while the Universe message detail screen is presented from Home.
    var isPresentingUniverseDetail: Bool = false

    /// ViewModel driving the Home-presented Universe detail screen, if any.
    private(set) var universeDetailViewModel: UniverseMessageDetailViewModel?

    /// `true` while the quick month picker is presented.
    var isPresentingMonthPicker: Bool = false

    /// ViewModel driving the month picker, if any.
    private(set) var monthPickerViewModel: MonthPickerViewModel?

    /// `true` while the year picker is presented.
    var isPresentingYearPicker: Bool = false

    /// ViewModel driving the year picker, if any.
    private(set) var yearPickerViewModel: YearPickerViewModel?

    /// `true` while the event editor modal is presented from Home.
    var isPresentingEventEditor: Bool = false

    /// ViewModel driving the Home-presented event editor, if any.
    private(set) var eventEditorViewModel: EventEditorViewModel?

    /// `true` while the event search screen is presented.
    var isPresentingEventSearch: Bool = false

    /// `true` while the Smart Daily Agenda is presented.
    var isPresentingSmartAgenda: Bool = false

    /// ViewModel driving the Smart Daily Agenda, if any.
    private(set) var smartAgendaViewModel: SmartAgendaViewModel?

    /// Last catalog bootstrap / persistence failure mapped for presentation.
    private(set) var lastError: EventPersistenceError?

    // MARK: - Lifecycle

    /// Creates the Home presentation model.
    /// - Parameters:
    ///   - eventPersistenceService: Service injected from the Composition Root.
    ///   - eventTemplateService: Optional offline templates façade.
    ///   - universeMessageViewModel: Universe Message card model.
    ///   - universeMessageEngine: Day-selection engine for Agenda.
    ///   - eventSearchViewModel: Shared search / filter model.
    ///   - makeUniverseHistoryViewModel: Factory for the history screen.
    ///   - makeUniverseMessageDetailViewModel: Factory for the detail screen.
    init(
        eventPersistenceService: EventPersistenceService,
        eventTemplateService: EventTemplateService? = nil,
        universeMessageViewModel: UniverseMessageViewModel,
        universeMessageEngine: UniverseMessageEngine? = nil,
        eventSearchViewModel: EventSearchViewModel? = nil,
        makeUniverseHistoryViewModel: @escaping () -> UniverseHistoryViewModel,
        makeUniverseMessageDetailViewModel: @escaping (UniverseMessageDetailContext) -> UniverseMessageDetailViewModel
    ) {
        self.eventPersistenceService = eventPersistenceService
        self.eventTemplateService = eventTemplateService
        self.universeMessageViewModel = universeMessageViewModel
        self.universeMessageEngine = universeMessageEngine
        self.eventSearchViewModel = eventSearchViewModel
            ?? EventSearchViewModel(persistenceService: eventPersistenceService)
        self.makeUniverseHistoryViewModel = makeUniverseHistoryViewModel
        self.makeUniverseMessageDetailViewModel = makeUniverseMessageDetailViewModel
    }

    // MARK: - Catalog

    /// Loads the event catalog, templates, and today’s Universe Message.
    ///
    /// Screen-level launch entry (not a service alias). Persistence/templates use ``refresh()``.
    func bootstrap() async {
        await bootstrapCatalog()
        await bootstrapTemplates()
        await universeMessageViewModel.loadInitial()
    }

    /// Loads the reactive event catalog and records failures on ``lastError``.
    func bootstrapCatalog() async {
        do {
            try await eventPersistenceService.refresh()
            lastError = nil
        } catch let error as EventPersistenceError {
            lastError = error
        } catch {
            lastError = .catalogLoadFailed
        }
    }

    /// Loads offline event templates; failures surface on ``lastError``.
    func bootstrapTemplates() async {
        guard let eventTemplateService else {
            return
        }
        do {
            try await eventTemplateService.refresh()
        } catch {
            lastError = .templatesLoadFailed
        }
    }

    /// Records a Composition Root persistence launch failure on ``lastError``.
    /// - Parameter error: Launch error from ``DependencyContainer/persistenceLaunchError``.
    func consumeLaunchError(_ error: EventPersistenceError) {
        lastError = error
    }

    /// `true` when the on-disk store is not writable.
    var isStorageUnavailable: Bool {
        eventPersistenceService.isWritable == false
    }

    /// Clears ``lastError`` after the user dismisses an alert.
    ///
    /// Store-unavailable errors are **not** cleared — the user must not believe
    /// writes are safe after dismissing a one-shot alert.
    func clearLastError() {
        if case .storeUnavailable = lastError {
            return
        }
        if isStorageUnavailable {
            lastError = .storeUnavailable
            return
        }
        lastError = nil
    }

    /// Localized message for ``lastError``, when present.
    var errorAlertMessage: String? {
        guard let lastError else {
            return nil
        }
        return EventEditorDisplayNames.message(for: lastError)
    }

    // MARK: - Intents

    /// Selects an in-month day and routes by event count.
    ///
    /// - 0 events → ``EventEditorView`` (create) — blocked when storage is unavailable
    /// - 1 event → ``EventEditorView`` (edit that event) — blocked when storage is unavailable
    /// - 2+ events → ``DayEventsView`` (safe read)
    /// - Parameter day: Calendar day tapped by the user.
    func selectDay(_ day: CalendarDay) async {
        guard day.isCurrentMonth else {
            return
        }

        selectedDate = day.date

        let existingEvents = eventPersistenceService.events(on: day.date)

        switch existingEvents.count {
        case 0:
            guard eventPersistenceService.isWritable else {
                lastError = .storeUnavailable
                return
            }
            presentEventEditorForCreation(on: day.date)
        case 1:
            guard eventPersistenceService.isWritable else {
                lastError = .storeUnavailable
                return
            }
            presentEventEditorForEditing(existingEvents[0])
        default:
            presentDayEvents(on: day.date)
        }
    }

    /// Dismisses the day-events screen.
    func dismissDayEvents() {
        isPresentingDayEvents = false
        dayEventsViewModel = nil
    }

    // MARK: - Month Navigation

    /// Syncs Home title/background with the grid's displayed month.
    ///
    /// Also mirrors smart day selection into ``selectedDate`` and refreshes the
    /// day-events panel when it is open so indicators and the list stay aligned.
    /// - Parameters:
    ///   - calendarGridViewModel: Source of the visible month/year.
    ///   - calendarAppearance: Calendar appearance for header + background.
    func syncDisplayedMonth(
        from calendarGridViewModel: CalendarGridViewModel,
        calendarAppearance: CalendarAppearanceManager
    ) {
        calendarAppearance.prepareDisplayedMonth(
            calendarGridViewModel.displayedMonth,
            year: calendarGridViewModel.displayedYear
        )
        if let selectedDay = calendarGridViewModel.selectedDay {
            selectedDate = selectedDay.date
            refreshDayEventsIfNeeded(for: selectedDay.date)
        } else {
            selectedDate = nil
        }
    }

    /// Updates the open day-events panel to the smart-selected day, if presented.
    private func refreshDayEventsIfNeeded(for date: Date) {
        guard isPresentingDayEvents, let dayEventsViewModel else {
            return
        }
        dayEventsViewModel.updateDate(date)
    }

    /// Navigates the calendar grid to the previous month and syncs theme.
    /// - Parameters:
    ///   - calendarGridViewModel: Grid that owns month structure.
    ///   - calendarAppearance: Calendar appearance for header + background.
    func goToPreviousMonth(
        calendarGridViewModel: CalendarGridViewModel,
        calendarAppearance: CalendarAppearanceManager
    ) {
        navigateMonth(
            .previous,
            calendarGridViewModel: calendarGridViewModel,
            calendarAppearance: calendarAppearance
        )
    }

    /// Navigates the calendar grid to the next month and syncs theme.
    /// - Parameters:
    ///   - calendarGridViewModel: Grid that owns month structure.
    ///   - calendarAppearance: Calendar appearance for header + background.
    func goToNextMonth(
        calendarGridViewModel: CalendarGridViewModel,
        calendarAppearance: CalendarAppearanceManager
    ) {
        navigateMonth(
            .next,
            calendarGridViewModel: calendarGridViewModel,
            calendarAppearance: calendarAppearance
        )
    }

    /// Applies a month navigation intent from chevrons or swipe and syncs theme.
    ///
    /// Safe under rapid consecutive swipes: each intent resolves to one
    /// ``CalendarGridViewModel/showMonth`` before the next is applied.
    /// - Parameters:
    ///   - intent: Direction / step count (`prefersAnimation` is Presentation-only).
    ///   - calendarGridViewModel: Grid that owns month structure.
    ///   - calendarAppearance: Calendar appearance for header + background.
    func navigateMonth(
        _ intent: CalendarMonthNavigationIntent,
        calendarGridViewModel: CalendarGridViewModel,
        calendarAppearance: CalendarAppearanceManager
    ) {
        let didChange = calendarGridViewModel.navigateMonth(intent)
        guard didChange else {
            return
        }
        syncDisplayedMonth(from: calendarGridViewModel, calendarAppearance: calendarAppearance)
    }

    /// Jumps to today and syncs header / background when the period changes.
    ///
    /// Skips theme work when the grid already shows today selected.
    /// - Parameters:
    ///   - calendarGridViewModel: Grid that owns month structure and selection.
    ///   - calendarAppearance: Calendar appearance for header + background.
    func goToToday(
        calendarGridViewModel: CalendarGridViewModel,
        calendarAppearance: CalendarAppearanceManager
    ) {
        let didChange = calendarGridViewModel.goToToday()
        guard didChange else {
            return
        }
        syncDisplayedMonth(from: calendarGridViewModel, calendarAppearance: calendarAppearance)
    }

    /// Presents the quick month picker for the grid's current year.
    /// - Parameter calendarGridViewModel: Source of the visible month/year.
    func presentMonthPicker(from calendarGridViewModel: CalendarGridViewModel) {
        monthPickerViewModel = MonthPickerViewModel(
            selectedMonth: calendarGridViewModel.displayedMonth,
            year: calendarGridViewModel.displayedYear
        )
        isPresentingMonthPicker = true
    }

    /// Applies a month chosen in the picker and dismisses it.
    ///
    /// Keeps ``MonthPickerViewModel/year`` unchanged. Updates grid, theme title,
    /// background, and event annotations for the new month.
    /// - Parameters:
    ///   - month: Selected month number (`1...12`).
    ///   - calendarGridViewModel: Grid to rebuild.
    ///   - calendarAppearance: Calendar appearance for header + background.
    func applyMonthPickerSelection(
        _ month: Int,
        calendarGridViewModel: CalendarGridViewModel,
        calendarAppearance: CalendarAppearanceManager
    ) {
        let year = monthPickerViewModel?.year ?? calendarGridViewModel.displayedYear
        let didChange = calendarGridViewModel.showMonth(month, year: year)
        if didChange {
            syncDisplayedMonth(from: calendarGridViewModel, calendarAppearance: calendarAppearance)
        }
        dismissMonthPicker()
    }

    /// Dismisses the month picker without changing the visible month.
    func dismissMonthPicker() {
        isPresentingMonthPicker = false
        monthPickerViewModel = nil
    }

    /// Presents the year picker for the grid's current month.
    /// - Parameter calendarGridViewModel: Source of the visible month/year.
    func presentYearPicker(from calendarGridViewModel: CalendarGridViewModel) {
        yearPickerViewModel = YearPickerViewModel(
            selectedYear: calendarGridViewModel.displayedYear,
            month: calendarGridViewModel.displayedMonth
        )
        isPresentingYearPicker = true
    }

    /// Applies a year chosen in the picker and dismisses it.
    ///
    /// Keeps ``YearPickerViewModel/month`` unchanged. Updates grid, theme title,
    /// background, and event annotations for the new year.
    /// - Parameters:
    ///   - year: Selected year.
    ///   - calendarGridViewModel: Grid to rebuild.
    ///   - calendarAppearance: Calendar appearance for header + background.
    func applyYearPickerSelection(
        _ year: Int,
        calendarGridViewModel: CalendarGridViewModel,
        calendarAppearance: CalendarAppearanceManager
    ) {
        let month = yearPickerViewModel?.month ?? calendarGridViewModel.displayedMonth
        let didChange = calendarGridViewModel.showMonth(month, year: year)
        if didChange {
            syncDisplayedMonth(from: calendarGridViewModel, calendarAppearance: calendarAppearance)
        }
        dismissYearPicker()
    }

    /// Dismisses the year picker without changing the visible year.
    func dismissYearPicker() {
        isPresentingYearPicker = false
        yearPickerViewModel = nil
    }

    /// Presents the Universe Message history screen.
    func presentUniverseHistory() {
        universeHistoryViewModel = makeUniverseHistoryViewModel()
        isPresentingUniverseHistory = true
    }

    /// Dismisses the Universe Message history screen.
    func dismissUniverseHistory() {
        isPresentingUniverseHistory = false
        universeHistoryViewModel = nil
    }

    /// Presents the Universe Message detail screen from the Home card.
    func presentUniverseMessageDetail() {
        let card = universeMessageViewModel
        let messageId = card.messageId ?? UniverseMessageEngine.defaultMessage.id
        let context = UniverseMessageDetailContext(
            messageId: messageId,
            dayStart: card.date,
            message: card.message,
            category: card.category,
            isFavorite: card.isFavorite
        )
        universeDetailViewModel = makeUniverseMessageDetailViewModel(context)
        isPresentingUniverseDetail = true
    }

    /// Dismisses the Universe Message detail screen opened from Home.
    func dismissUniverseMessageDetail() {
        isPresentingUniverseDetail = false
        universeDetailViewModel = nil
    }

    /// Presents the event search / filter screen.
    func presentEventSearch() {
        isPresentingEventSearch = true
    }

    /// Dismisses the event search screen (criteria remain applied to the calendar).
    func dismissEventSearch() {
        isPresentingEventSearch = false
    }

    /// Presents the Smart Daily Agenda for today.
    func presentSmartAgenda() {
        smartAgendaViewModel = SmartAgendaViewModel(
            day: Date(),
            persistenceService: eventPersistenceService,
            universeEngine: universeMessageEngine
        )
        isPresentingSmartAgenda = true
    }

    /// Dismisses the Smart Daily Agenda.
    func dismissSmartAgenda() {
        isPresentingSmartAgenda = false
        smartAgendaViewModel = nil
    }

    /// Dismisses the Home-presented event editor.
    ///
    /// Calendar indicators refresh via the reactive ``EventPersistenceService`` catalog.
    func dismissEventEditor() {
        isPresentingEventEditor = false
        eventEditorViewModel = nil
    }

    // MARK: - Private

    /// Presents the day-events list for the given date.
    private func presentDayEvents(on date: Date) {
        dayEventsViewModel = DayEventsViewModel(
            date: date,
            persistenceService: eventPersistenceService,
            templateService: eventTemplateService,
            searchViewModel: eventSearchViewModel
        )
        isPresentingDayEvents = true
    }

    /// Presents the event editor in create mode.
    private func presentEventEditorForCreation(on date: Date) {
        let editor = EventEditorViewModel(
            persistenceService: eventPersistenceService,
            templateService: eventTemplateService,
            initialDate: date
        )
        editor.prepareForCreation(on: date)
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    /// Presents the event editor in edit mode for a single existing event.
    ///
    /// Resolves the persisted master so virtual recurrence occurrences are not
    /// saved with occurrence-shifted dates (same contract as Day Events / Agenda).
    private func presentEventEditorForEditing(_ event: Event) {
        let master = resolveMasterSnapshot(for: event)
        let editor = EventEditorViewModel(
            persistenceService: eventPersistenceService,
            templateService: eventTemplateService,
            initialDate: master.date,
            event: master
        )
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    /// Prefers the catalog master when editing so occurrence dates are not saved.
    private func resolveMasterSnapshot(for event: Event) -> Event {
        eventPersistenceService.event(id: event.id) ?? event
    }
}

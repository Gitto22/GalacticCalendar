//
//  SmartAgendaViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Presentation model for the Smart Daily Agenda (Sprint 6.8).
///
/// ## Responsibilities
/// - Own the focused agenda day and derived snapshot.
/// - Read day events from ``EventPersistenceService`` (Observation).
/// - Resolve the Universe Message for the focused day via ``UniverseMessageEngine``.
/// - Expose summary, timeline, free blocks, next event, and end-of-day metrics.
///
/// ## Non-responsibilities
/// - No SwiftUI.
/// - No SwiftData / repository access.
/// - No IA / predictions / widgets.
@MainActor
@Observable
final class SmartAgendaViewModel {

    // MARK: - Dependencies

    private let persistenceService: EventPersistenceService
    private let universeEngine: UniverseMessageEngine?
    private let calendar: Calendar
    private let now: () -> Date

    // MARK: - State

    /// Focused agenda day (start-of-day).
    private(set) var day: Date

    /// Localized Universe Message body for ``day``.
    private(set) var universeMessage: String = ""

    /// Universe category for Observation / future styling.
    private(set) var universeCategory: UniverseCategory = .motivation

    /// `true` while the nested event editor is presented.
    var isPresentingEventEditor: Bool = false

    /// Nested editor ViewModel, if any.
    private(set) var eventEditorViewModel: EventEditorViewModel?

    // MARK: - Lifecycle

    init(
        day: Date = Date(),
        persistenceService: EventPersistenceService,
        universeEngine: UniverseMessageEngine? = nil,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.persistenceService = persistenceService
        self.universeEngine = universeEngine
        self.calendar = calendar
        self.now = now
        self.day = calendar.startOfDay(for: day)
    }

    // MARK: - Bootstrap

    /// Ensures the Universe catalog is loaded and publishes the day’s message.
    func bootstrap() async {
        await universeEngine?.refreshIfNeeded()
        refreshUniverseMessage()
    }

    // MARK: - Derived Snapshot

    /// Full agenda snapshot; tracks catalog revision for Observation.
    var snapshot: AgendaDaySnapshot {
        _ = persistenceService.eventsRevision
        let events = persistenceService.events(on: day)
        return AgendaTimelineBuilder.build(
            events: events,
            day: day,
            now: now(),
            calendar: calendar
        )
    }

    var summary: AgendaDaySummary { snapshot.summary }
    var allDayEvents: [Event] { snapshot.allDayEvents }
    var timeline: [AgendaTimelineItem] { snapshot.timeline }
    var freeBlocks: [AgendaFreeBlock] { snapshot.freeBlocks }
    var nextEvent: Event? { snapshot.nextEvent }
    var isEmptyDay: Bool { summary.eventCount == 0 }

    // MARK: - Formatting helpers (logic stays in VM)

    var weekdayTitle: String {
        day.formatted(
            Date.FormatStyle().weekday(.wide).locale(.autoupdatingCurrent)
        )
    }

    var dateTitle: String {
        day.formatted(
            Date.FormatStyle(date: .complete, time: .omitted)
                .locale(.autoupdatingCurrent)
        )
    }

    func durationText(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        if hours > 0, minutes > 0 {
            return String(
                format: String(localized: "agenda_duration_hm_format"),
                locale: .current,
                hours,
                minutes
            )
        }
        if hours > 0 {
            return String(
                format: String(localized: "agenda_duration_h_format"),
                locale: .current,
                hours
            )
        }
        return String(
            format: String(localized: "agenda_duration_m_format"),
            locale: .current,
            minutes
        )
    }

    func timeRangeText(start: Date, end: Date) -> String {
        let startText = start.formatted(date: .omitted, time: .shortened)
        let endText = end.formatted(date: .omitted, time: .shortened)
        return String(
            format: String(localized: "agenda_time_range_format"),
            locale: .current,
            startText,
            endText
        )
    }

    func eventDurationText(_ event: Event) -> String {
        let end = event.endDate
            ?? event.startDate.addingTimeInterval(AgendaTimelineBuilder.Defaults.defaultEventDuration)
        return durationText(end.timeIntervalSince(event.startDate))
    }

    // MARK: - Navigation

    func goToPreviousDay() {
        guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else {
            return
        }
        day = calendar.startOfDay(for: previous)
        refreshUniverseMessage()
    }

    func goToNextDay() {
        guard let next = calendar.date(byAdding: .day, value: 1, to: day) else {
            return
        }
        day = calendar.startOfDay(for: next)
        refreshUniverseMessage()
    }

    func goToToday() {
        let today = calendar.startOfDay(for: now())
        guard today != day else { return }
        day = today
        refreshUniverseMessage()
    }

    var isShowingToday: Bool {
        calendar.isDate(day, inSameDayAs: now())
    }

    // MARK: - Editor

    func presentEdit(for event: Event) {
        guard persistenceService.isWritable else {
            return
        }
        let master = persistenceService.event(id: event.id) ?? event
        let editor = EventEditorViewModel(
            persistenceService: persistenceService,
            initialDate: master.date,
            event: master
        )
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    func presentNewEvent() {
        guard persistenceService.isWritable else {
            return
        }
        let editor = EventEditorViewModel(
            persistenceService: persistenceService,
            initialDate: day
        )
        editor.prepareForCreation(on: day)
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    func dismissEventEditor() {
        isPresentingEventEditor = false
        eventEditorViewModel = nil
    }

    // MARK: - Private

    private func refreshUniverseMessage() {
        guard let universeEngine else {
            universeMessage = ""
            return
        }
        let selected = universeEngine.message(for: day)
        universeCategory = selected.category
        universeMessage = String(localized: String.LocalizationValue(selected.textKey))
    }
}

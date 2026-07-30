//
//  EventSearchViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Presentation model for incremental event search / filter (Sprint 6.7).
///
/// ## Responsibilities
/// - Own query state (text + facets + quick date range).
/// - Derive ``criteria`` and ``results`` reactively from the catalog.
///
/// ## Non-responsibilities
/// - No SwiftData access.
/// - No mutation of events.
@MainActor
@Observable
final class EventSearchViewModel {

    // MARK: - Dependencies

    private let persistenceService: EventPersistenceService
    private let calendar: Calendar

    // MARK: - Query State

    var searchText: String = ""

    var selectedTagIDs: Set<String> = []
    var selectedPriorities: Set<EventPriority> = []
    var selectedColors: Set<EventColor> = []
    var selectedCategories: Set<EventCategory> = []

    var isAllDay: Bool?
    var isMultiDay: Bool?
    var isRecurring: Bool?
    var hasReminder: Bool?

    var quickDateRange: EventSearchCriteria.QuickDateRange = .any

    /// Concrete day override (clears quick range interval when set).
    var onDate: Date?

    /// When `true`, calendar / day list consumers should apply ``criteria``.
    var appliesToCalendar: Bool = true

    // MARK: - Lifecycle

    init(
        persistenceService: EventPersistenceService,
        calendar: Calendar = .current
    ) {
        self.persistenceService = persistenceService
        self.calendar = calendar
    }

    // MARK: - Derived Criteria

    /// Incremental criteria rebuilt from query state.
    var criteria: EventSearchCriteria {
        var value = EventSearchCriteria(
            textQuery: searchText,
            tagIDs: selectedTagIDs,
            priorities: selectedPriorities,
            colors: selectedColors,
            categories: selectedCategories,
            isAllDay: isAllDay,
            isMultiDay: isMultiDay,
            isRecurring: isRecurring,
            hasReminder: hasReminder,
            onDate: onDate,
            dateInterval: nil
        )
        if onDate == nil {
            value = value.applying(quickRange: quickDateRange, calendar: calendar)
        }
        return value
    }

    /// Criteria consumed by grid / day list (`empty` when not applied).
    var calendarCriteria: EventSearchCriteria {
        appliesToCalendar ? criteria : EventSearchCriteria()
    }

    // MARK: - Results

    /// Matching masters; tracks catalog revision for Observation.
    var results: [Event] {
        _ = persistenceService.eventsRevision
        return persistenceService.events(matching: criteria)
    }

    var hasActiveFilters: Bool {
        criteria.isEmpty == false
    }

    var isResultsEmpty: Bool {
        hasActiveFilters && results.isEmpty
    }

    // MARK: - Intents

    func toggleTag(_ preset: EventTagPreset) {
        let id = preset.rawValue
        if selectedTagIDs.contains(id) {
            selectedTagIDs.remove(id)
        } else {
            selectedTagIDs.insert(id)
        }
    }

    func togglePriority(_ priority: EventPriority) {
        if selectedPriorities.contains(priority) {
            selectedPriorities.remove(priority)
        } else {
            selectedPriorities.insert(priority)
        }
    }

    func toggleColor(_ color: EventColor) {
        if selectedColors.contains(color) {
            selectedColors.remove(color)
        } else {
            selectedColors.insert(color)
        }
    }

    func toggleCategory(_ category: EventCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    func setQuickDateRange(_ range: EventSearchCriteria.QuickDateRange) {
        quickDateRange = range
        onDate = nil
    }

    func clearFilters() {
        searchText = ""
        selectedTagIDs = []
        selectedPriorities = []
        selectedColors = []
        selectedCategories = []
        isAllDay = nil
        isMultiDay = nil
        isRecurring = nil
        hasReminder = nil
        quickDateRange = .any
        onDate = nil
    }

    func cycleTriState(_ keyPath: ReferenceWritableKeyPath<EventSearchViewModel, Bool?>) {
        switch self[keyPath: keyPath] {
        case nil:
            self[keyPath: keyPath] = true
        case true?:
            self[keyPath: keyPath] = false
        case false?:
            self[keyPath: keyPath] = nil
        }
    }
}

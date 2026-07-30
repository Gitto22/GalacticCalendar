//
//  EventSearchCriteria.swift
//  GalacticCalendar
//

import Foundation

/// Conjunctive search / filter criteria for ``Event`` (Sprint 6.7).
///
/// ## Pipeline
/// Apply via ``filter(_:)`` / ``EventCatalogService/events(matching:)`` in a
/// **single pass**. Empty / `nil` facets mean “no constraint”.
///
/// ## Notes
/// Event “notes” are stored as ``Event/description``. Date-interval matching that
/// needs recurrence expansion is applied by the catalog after ``matches(_:)``.
struct EventSearchCriteria: Equatable, Sendable, Hashable {

    // MARK: - Text

    /// Free-text query matched against title, description/notes, and tag labels.
    var textQuery: String = ""

    // MARK: - Organization

    /// When non-empty, event must include **all** listed tag ids (AND).
    var tagIDs: Set<String> = []

    /// When non-empty, event priority must be one of these (OR).
    var priorities: Set<EventPriority> = []

    /// When non-empty, event color must be one of these (OR).
    var colors: Set<EventColor> = []

    /// When non-empty, event category must be one of these (OR).
    var categories: Set<EventCategory> = []

    // MARK: - Schedule facets

    /// `nil` = any; otherwise must match ``Event/isAllDay``.
    var isAllDay: Bool?

    /// `nil` = any; otherwise must match ``Event/isMultiDay``.
    var isMultiDay: Bool?

    /// `nil` = any; otherwise must match ``RepeatRule/isRecurring``.
    var isRecurring: Bool?

    /// `nil` = any; `true` requires a reminder; `false` requires none.
    var hasReminder: Bool?

    // MARK: - Dates

    /// Concrete calendar day the event must occur on (catalog expands recurrence).
    var onDate: Date?

    /// Inclusive start / exclusive end interval the event must overlap.
    var dateInterval: DateInterval?

    // MARK: - Emptiness

    /// `true` when no facet or text constraint is active.
    var isEmpty: Bool {
        normalizedTextQuery.isEmpty
            && tagIDs.isEmpty
            && priorities.isEmpty
            && colors.isEmpty
            && categories.isEmpty
            && isAllDay == nil
            && isMultiDay == nil
            && isRecurring == nil
            && hasReminder == nil
            && onDate == nil
            && dateInterval == nil
    }

    /// `true` when a concrete day or interval must be evaluated (may need expansion).
    var hasDateConstraint: Bool {
        onDate != nil || dateInterval != nil
    }

    /// Trimmed lowercase query used for matching.
    var normalizedTextQuery: String {
        textQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Matching (content + facets; not recurrence-expanded dates)

    /// Returns whether ``event`` satisfies every active non-expanded constraint.
    ///
    /// Date constraints that require recurrence expansion are **not** fully
    /// evaluated here — the catalog applies them in the same filter pass.
    func matches(_ event: Event) -> Bool {
        if matchesText(event) == false { return false }
        if matchesTags(event) == false { return false }
        if matchesPriorities(event) == false { return false }
        if matchesColors(event) == false { return false }
        if matchesCategories(event) == false { return false }
        if matchesAllDay(event) == false { return false }
        if matchesMultiDay(event) == false { return false }
        if matchesRecurring(event) == false { return false }
        if matchesReminder(event) == false { return false }
        return true
    }

    /// Single-pass filter over ``events`` (content + facets only).
    func filter(_ events: [Event]) -> [Event] {
        if isEmpty && hasDateConstraint == false {
            return events
        }
        var result: [Event] = []
        result.reserveCapacity(events.count)
        for event in events where matches(event) {
            result.append(event)
        }
        return result
    }

    // MARK: - Private facet helpers

    private func matchesText(_ event: Event) -> Bool {
        let query = normalizedTextQuery
        guard query.isEmpty == false else { return true }
        if event.title.lowercased().contains(query) { return true }
        if event.description.lowercased().contains(query) { return true }
        for tag in event.tags {
            if tag.id.lowercased().contains(query) { return true }
            if let label = tag.customLabel?.lowercased(), label.contains(query) {
                return true
            }
        }
        return false
    }

    private func matchesTags(_ event: Event) -> Bool {
        guard tagIDs.isEmpty == false else { return true }
        let eventTagIDs = Set(event.tags.map(\.id))
        return tagIDs.isSubset(of: eventTagIDs)
    }

    private func matchesPriorities(_ event: Event) -> Bool {
        guard priorities.isEmpty == false else { return true }
        return priorities.contains(event.priority)
    }

    private func matchesColors(_ event: Event) -> Bool {
        guard colors.isEmpty == false else { return true }
        return colors.contains(event.color)
    }

    private func matchesCategories(_ event: Event) -> Bool {
        guard categories.isEmpty == false else { return true }
        if categories.contains(event.category) { return true }
        // Also accept events whose tags map to the requested categories.
        for tag in event.tags {
            if let preset = EventTagPreset(rawValue: tag.id),
               categories.contains(preset.asCategory) {
                return true
            }
        }
        return false
    }

    private func matchesAllDay(_ event: Event) -> Bool {
        guard let isAllDay else { return true }
        return event.isAllDay == isAllDay
    }

    private func matchesMultiDay(_ event: Event) -> Bool {
        guard let isMultiDay else { return true }
        return event.isMultiDay == isMultiDay
    }

    private func matchesRecurring(_ event: Event) -> Bool {
        guard let isRecurring else { return true }
        return event.repeatRule.isRecurring == isRecurring
    }

    private func matchesReminder(_ event: Event) -> Bool {
        guard let hasReminder else { return true }
        let present = event.reminder != nil
        return present == hasReminder
    }
}

// MARK: - Quick date ranges

extension EventSearchCriteria {

    /// Preset ranges for “today / this week / this month” chips.
    enum QuickDateRange: String, CaseIterable, Identifiable, Sendable {
        case any
        case today
        case thisWeek
        case thisMonth

        var id: String { rawValue }

        /// Builds an interval in ``calendar`` starting from ``now``.
        func dateInterval(now: Date = Date(), calendar: Calendar = .current) -> DateInterval? {
            let startOfDay = calendar.startOfDay(for: now)
            switch self {
            case .any:
                return nil
            case .today:
                guard let end = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                    return nil
                }
                return DateInterval(start: startOfDay, end: end)
            case .thisWeek:
                guard
                    let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
                    let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)
                else {
                    return nil
                }
                return DateInterval(start: weekStart, end: weekEnd)
            case .thisMonth:
                guard
                    let monthStart = calendar.dateInterval(of: .month, for: now)?.start,
                    let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)
                else {
                    return nil
                }
                return DateInterval(start: monthStart, end: monthEnd)
            }
        }
    }

    /// Returns a copy with ``dateInterval`` / ``onDate`` derived from a quick range.
    func applying(quickRange: QuickDateRange, now: Date = Date(), calendar: Calendar = .current) -> EventSearchCriteria {
        var copy = self
        copy.onDate = nil
        copy.dateInterval = quickRange.dateInterval(now: now, calendar: calendar)
        return copy
    }
}

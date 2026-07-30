//
//  EventOccurrence.swift
//  GalacticCalendar
//

import Foundation

/// A dynamically computed occurrence of a stored master ``Event``.
///
/// Not persisted. Identity is stable for a given master + occurrence start so
/// SwiftUI lists can diff without creating SwiftData rows.
struct EventOccurrence: Identifiable, Equatable, Sendable, Hashable {

    // MARK: - Identity

    /// Stable id: master UUID + occurrence start epoch.
    let id: String

    /// Persisted master event this occurrence expands from.
    let master: Event

    /// Absolute start of this occurrence.
    let occurrenceStart: Date

    /// Absolute end of this occurrence (`nil` when the master has no end).
    let occurrenceEnd: Date?

    /// 1-based index in the series (master start = 1).
    let occurrenceIndex: Int

    // MARK: - Lifecycle

    init(
        master: Event,
        occurrenceStart: Date,
        occurrenceEnd: Date?,
        occurrenceIndex: Int
    ) {
        self.master = master
        self.occurrenceStart = occurrenceStart
        self.occurrenceEnd = occurrenceEnd
        self.occurrenceIndex = occurrenceIndex
        self.id = "\(master.id.uuidString)-\(Int(occurrenceStart.timeIntervalSince1970))"
    }

    // MARK: - Presentation

    /// Materializes a presentation ``Event`` with shifted dates (same master id).
    ///
    /// Used by day lists and grid indicators. Edits still target the master row.
    func asEvent() -> Event {
        Event(
            id: master.id,
            title: master.title,
            description: master.description,
            date: occurrenceStart,
            endDate: occurrenceEnd,
            isAllDay: master.isAllDay,
            timeZoneIdentifier: master.timeZoneIdentifier,
            reminder: master.reminder,
            repeatRule: master.repeatRule,
            category: master.category,
            tags: master.tags,
            priority: master.priority,
            status: master.status,
            color: master.color,
            createdAt: master.createdAt,
            updatedAt: master.updatedAt
        )
    }
}

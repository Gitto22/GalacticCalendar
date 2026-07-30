//
//  EventEntity.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// SwiftData persistence model for ``Event``.
///
/// Kept separate from the Domain ``Event`` model.
/// Stored enum fields use raw strings to stay CloudKit-friendly.
@Model
final class EventEntity {

    // MARK: - Identity

    /// Stable unique identifier mirrored from the domain model.
    @Attribute(.unique) var id: UUID

    // MARK: - Content

    /// Persisted event title.
    var title: String

    /// Persisted event description.
    ///
    /// Named `eventDescription` to avoid colliding with `CustomStringConvertible`.
    var eventDescription: String

    /// Persisted start date and time.
    var date: Date

    /// Optional end date and time.
    ///
    /// Later calendar day than ``date`` = multi-day event (``Event/isMultiDay``).
    var endDate: Date?

    /// Whether the event is all-day (`false` for legacy rows after lightweight migration).
    var isAllDay: Bool

    /// Optional IANA time zone identifier (nil = legacy / device current on read).
    var timeZoneIdentifier: String?

    /// Optional reminder fire date.
    var reminder: Date?

    /// Raw value for ``RepeatRule`` persistence encoding.
    ///
    /// Stores a plain frequency string or a versioned JSON envelope
    /// produced by ``RepeatRule/encodeForPersistence()``.
    var repeatRuleRawValue: String

    // MARK: - Classification

    /// Raw value for ``EventCategory``.
    var categoryRawValue: String

    /// Raw value for ``EventPriority``.
    var priorityRawValue: String

    /// Raw value for ``EventStatus``.
    var statusRawValue: String

    /// Raw value for ``EventColor``.
    var colorRawValue: String

    /// JSON-encoded ``EventTag`` list (`[]` when empty / legacy).
    var tagsRawValue: String

    // MARK: - Timestamps

    /// Creation timestamp.
    var createdAt: Date

    /// Last update timestamp.
    var updatedAt: Date

    // MARK: - Lifecycle

    /// Creates a persistence entity.
    init(
        id: UUID,
        title: String,
        eventDescription: String,
        date: Date,
        endDate: Date? = nil,
        isAllDay: Bool = false,
        timeZoneIdentifier: String? = nil,
        reminder: Date?,
        repeatRuleRawValue: String,
        categoryRawValue: String,
        priorityRawValue: String,
        statusRawValue: String,
        colorRawValue: String,
        tagsRawValue: String = "[]",
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.date = date
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.timeZoneIdentifier = timeZoneIdentifier
        self.reminder = reminder
        self.repeatRuleRawValue = repeatRuleRawValue
        self.categoryRawValue = categoryRawValue
        self.priorityRawValue = priorityRawValue
        self.statusRawValue = statusRawValue
        self.colorRawValue = colorRawValue
        self.tagsRawValue = tagsRawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

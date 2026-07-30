//
//  EventTemplateEntity.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// SwiftData persistence model for ``EventTemplate``.
@Model
final class EventTemplateEntity {

    @Attribute(.unique) var id: UUID
    var name: String
    var title: String
    var eventDescription: String
    var isAllDay: Bool
    var durationSeconds: Double
    var repeatRuleRawValue: String
    var categoryRawValue: String
    var tagsRawValue: String
    var priorityRawValue: String
    var statusRawValue: String
    var colorRawValue: String
    var timeZoneIdentifier: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        name: String,
        title: String,
        eventDescription: String,
        isAllDay: Bool,
        durationSeconds: Double,
        repeatRuleRawValue: String,
        categoryRawValue: String,
        tagsRawValue: String,
        priorityRawValue: String,
        statusRawValue: String,
        colorRawValue: String,
        timeZoneIdentifier: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.eventDescription = eventDescription
        self.isAllDay = isAllDay
        self.durationSeconds = durationSeconds
        self.repeatRuleRawValue = repeatRuleRawValue
        self.categoryRawValue = categoryRawValue
        self.tagsRawValue = tagsRawValue
        self.priorityRawValue = priorityRawValue
        self.statusRawValue = statusRawValue
        self.colorRawValue = colorRawValue
        self.timeZoneIdentifier = timeZoneIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

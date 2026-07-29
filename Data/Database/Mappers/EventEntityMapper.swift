//
//  EventEntityMapper.swift
//  GalacticCalendar
//

import Foundation

/// Maps between Domain ``Event`` and persistence ``EventEntity``.
enum EventEntityMapper {

    // MARK: - To Persistence

    /// Creates a new SwiftData entity from a domain event.
    /// - Parameter event: Domain event.
    /// - Returns: Persistence entity ready for insertion.
    static func makeEntity(from event: Event) -> EventEntity {
        EventEntity(
            id: event.id,
            title: event.title,
            eventDescription: event.description,
            date: event.date,
            endDate: event.endDate,
            timeZoneIdentifier: event.timeZoneIdentifier,
            reminder: event.reminder,
            repeatRuleRawValue: event.repeatRule.encodeForPersistence(),
            categoryRawValue: event.category.rawValue,
            priorityRawValue: event.priority.rawValue,
            statusRawValue: event.status.rawValue,
            colorRawValue: event.color.rawValue,
            createdAt: event.createdAt,
            updatedAt: event.updatedAt
        )
    }

    /// Writes domain values onto an existing persistence entity.
    /// - Parameters:
    ///   - event: Source domain event.
    ///   - entity: Target persistence entity.
    static func apply(_ event: Event, to entity: EventEntity) {
        entity.title = event.title
        entity.eventDescription = event.description
        entity.date = event.date
        entity.endDate = event.endDate
        entity.timeZoneIdentifier = event.timeZoneIdentifier
        entity.reminder = event.reminder
        entity.repeatRuleRawValue = event.repeatRule.encodeForPersistence()
        entity.categoryRawValue = event.category.rawValue
        entity.priorityRawValue = event.priority.rawValue
        entity.statusRawValue = event.status.rawValue
        entity.colorRawValue = event.color.rawValue
        entity.updatedAt = event.updatedAt
    }

    // MARK: - To Domain

    /// Creates a domain event from a persistence entity.
    /// - Parameter entity: Persistence entity.
    /// - Returns: Domain event.
    static func makeDomain(from entity: EventEntity) -> Event {
        Event(
            id: entity.id,
            title: entity.title,
            description: entity.eventDescription,
            date: entity.date,
            endDate: entity.endDate,
            timeZoneIdentifier: entity.timeZoneIdentifier ?? TimeZone.current.identifier,
            reminder: entity.reminder,
            repeatRule: RepeatRule.decodeFromPersistence(entity.repeatRuleRawValue),
            category: EventCategory(rawValue: entity.categoryRawValue) ?? .other,
            priority: EventPriority(rawValue: entity.priorityRawValue) ?? .medium,
            status: EventStatus(rawValue: entity.statusRawValue) ?? .pending,
            color: EventColor(rawValue: entity.colorRawValue) ?? .green,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
}

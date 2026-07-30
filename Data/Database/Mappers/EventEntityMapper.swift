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
    /// - Throws: ``EventRepositoryError/corruptData`` when encoding fails.
    static func makeEntity(from event: Event) throws -> EventEntity {
        do {
            return EventEntity(
                id: event.id,
                title: event.title,
                eventDescription: event.description,
                date: event.date,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                timeZoneIdentifier: event.timeZoneIdentifier,
                reminder: event.reminder,
                repeatRuleRawValue: try event.repeatRule.encodeForPersistence(),
                categoryRawValue: event.category.rawValue,
                priorityRawValue: event.priority.rawValue,
                statusRawValue: event.status.rawValue,
                colorRawValue: event.color.rawValue,
                tagsRawValue: try EventTagCodec.encode(event.tags),
                createdAt: event.createdAt,
                updatedAt: event.updatedAt
            )
        } catch {
            throw EventRepositoryError.corruptData
        }
    }

    /// Writes domain values onto an existing persistence entity.
    /// - Parameters:
    ///   - event: Source domain event.
    ///   - entity: Target persistence entity.
    /// - Throws: ``EventRepositoryError/corruptData`` when encoding fails.
    static func apply(_ event: Event, to entity: EventEntity) throws {
        do {
            entity.title = event.title
            entity.eventDescription = event.description
            entity.date = event.date
            entity.endDate = event.endDate
            entity.isAllDay = event.isAllDay
            entity.timeZoneIdentifier = event.timeZoneIdentifier
            entity.reminder = event.reminder
            entity.repeatRuleRawValue = try event.repeatRule.encodeForPersistence()
            entity.categoryRawValue = event.category.rawValue
            entity.priorityRawValue = event.priority.rawValue
            entity.statusRawValue = event.status.rawValue
            entity.colorRawValue = event.color.rawValue
            entity.tagsRawValue = try EventTagCodec.encode(event.tags)
            entity.updatedAt = event.updatedAt
        } catch {
            throw EventRepositoryError.corruptData
        }
    }

    // MARK: - To Domain

    /// Creates a domain event from a persistence entity.
    /// - Parameter entity: Persistence entity.
    /// - Returns: Domain event.
    /// - Throws: ``EventRepositoryError/corruptData`` when decoding invents nothing safely.
    static func makeDomain(from entity: EventEntity) throws -> Event {
        do {
            let tags = try EventTagCodec.decode(entity.tagsRawValue)
            guard let category = EventCategory(rawValue: entity.categoryRawValue) else {
                throw EventPersistenceCodecError.decodingFailed
            }
            guard let priority = EventPriority(persisted: entity.priorityRawValue) else {
                throw EventPersistenceCodecError.decodingFailed
            }
            guard let status = EventStatus(rawValue: entity.statusRawValue) else {
                throw EventPersistenceCodecError.decodingFailed
            }
            guard let color = EventColor(rawValue: entity.colorRawValue) else {
                throw EventPersistenceCodecError.decodingFailed
            }

            return Event(
                id: entity.id,
                title: entity.title,
                description: entity.eventDescription,
                date: entity.date,
                endDate: entity.endDate,
                isAllDay: entity.isAllDay,
                timeZoneIdentifier: entity.timeZoneIdentifier ?? TimeZone.current.identifier,
                reminder: entity.reminder,
                repeatRule: try RepeatRule.decodeFromPersistence(entity.repeatRuleRawValue),
                category: category,
                tags: tags,
                priority: priority,
                status: status,
                color: color,
                createdAt: entity.createdAt,
                updatedAt: entity.updatedAt
            )
        } catch is EventPersistenceCodecError {
            throw EventRepositoryError.corruptData
        } catch EventRepositoryError.corruptData {
            throw EventRepositoryError.corruptData
        } catch {
            throw EventRepositoryError.corruptData
        }
    }
}

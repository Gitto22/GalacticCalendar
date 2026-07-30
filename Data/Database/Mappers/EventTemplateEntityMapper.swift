//
//  EventTemplateEntityMapper.swift
//  GalacticCalendar
//

import Foundation

/// Maps between Domain ``EventTemplate`` and ``EventTemplateEntity``.
enum EventTemplateEntityMapper {

    static func makeEntity(from template: EventTemplate) throws -> EventTemplateEntity {
        do {
            return EventTemplateEntity(
                id: template.id,
                name: template.name,
                title: template.title,
                eventDescription: template.description,
                isAllDay: template.isAllDay,
                durationSeconds: template.durationSeconds,
                repeatRuleRawValue: try template.repeatRule.encodeForPersistence(),
                categoryRawValue: template.category.rawValue,
                tagsRawValue: try EventTagCodec.encode(template.tags),
                priorityRawValue: template.priority.rawValue,
                statusRawValue: template.status.rawValue,
                colorRawValue: template.color.rawValue,
                timeZoneIdentifier: template.timeZoneIdentifier,
                createdAt: template.createdAt,
                updatedAt: template.updatedAt
            )
        } catch {
            throw EventTemplateRepositoryError.corruptData
        }
    }

    static func apply(_ template: EventTemplate, to entity: EventTemplateEntity) throws {
        do {
            entity.name = template.name
            entity.title = template.title
            entity.eventDescription = template.description
            entity.isAllDay = template.isAllDay
            entity.durationSeconds = template.durationSeconds
            entity.repeatRuleRawValue = try template.repeatRule.encodeForPersistence()
            entity.categoryRawValue = template.category.rawValue
            entity.tagsRawValue = try EventTagCodec.encode(template.tags)
            entity.priorityRawValue = template.priority.rawValue
            entity.statusRawValue = template.status.rawValue
            entity.colorRawValue = template.color.rawValue
            entity.timeZoneIdentifier = template.timeZoneIdentifier
            entity.updatedAt = template.updatedAt
        } catch {
            throw EventTemplateRepositoryError.corruptData
        }
    }

    static func makeDomain(from entity: EventTemplateEntity) throws -> EventTemplate {
        do {
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

            return EventTemplate(
                id: entity.id,
                name: entity.name,
                title: entity.title,
                description: entity.eventDescription,
                isAllDay: entity.isAllDay,
                durationSeconds: entity.durationSeconds,
                repeatRule: try RepeatRule.decodeFromPersistence(entity.repeatRuleRawValue),
                category: category,
                tags: try EventTagCodec.decode(entity.tagsRawValue),
                priority: priority,
                status: status,
                color: color,
                timeZoneIdentifier: entity.timeZoneIdentifier,
                createdAt: entity.createdAt,
                updatedAt: entity.updatedAt
            )
        } catch {
            throw EventTemplateRepositoryError.corruptData
        }
    }
}

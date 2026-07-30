//
//  EventTag.swift
//  GalacticCalendar
//

import Foundation

/// Built-in event tag presets (CloudKit-friendly raw ids).
///
/// Custom user tags (Sprint 6.5+) use ``EventTag/custom(id:label:)`` without
/// expanding this enum.
enum EventTagPreset: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    // MARK: - Cases

    case work
    case personal
    case health
    case family
    case travel
    case finances
    case studies

    // MARK: - Identifiable

    var id: String { rawValue }

    /// Maps a legacy single ``EventCategory`` into a preset tag when possible.
    static func from(category: EventCategory) -> EventTagPreset? {
        switch category {
        case .work: .work
        case .personal: .personal
        case .health: .health
        case .family: .family
        case .travel: .travel
        case .finances: .finances
        case .studies: .studies
        case .other: nil
        }
    }

    /// Maps this preset back to ``EventCategory`` for legacy single-category fields.
    var asCategory: EventCategory {
        switch self {
        case .work: .work
        case .personal: .personal
        case .health: .health
        case .family: .family
        case .travel: .travel
        case .finances: .finances
        case .studies: .studies
        }
    }
}

/// A classification tag attached to an ``Event``.
///
/// Events may carry several tags. Presets are localized by ``id``;
/// ``customLabel`` prepares future user-defined tags (not editable in Sprint 6.4 UI).
struct EventTag: Identifiable, Hashable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Stable persistence id (`work`, … or a future custom UUID string).
    let id: String

    /// Optional display label for custom tags. `nil` for presets.
    var customLabel: String?

    // MARK: - Factories

    /// Creates a preset tag.
    static func preset(_ preset: EventTagPreset) -> EventTag {
        EventTag(id: preset.rawValue, customLabel: nil)
    }

    /// Creates a custom tag (architecture hook; not offered in the 6.4 editor yet).
    static func custom(id: String = UUID().uuidString, label: String) -> EventTag {
        EventTag(id: id, customLabel: label)
    }

    // MARK: - Derived

    /// Matching preset, if this tag is built-in.
    var preset: EventTagPreset? {
        guard customLabel == nil else {
            return nil
        }
        return EventTagPreset(rawValue: id)
    }

    /// `true` when this is a user-defined tag.
    var isCustom: Bool {
        customLabel != nil || EventTagPreset(rawValue: id) == nil
    }
}

// MARK: - Persistence Codec

enum EventTagCodec {

    // MARK: - Encode / Decode

    /// Encodes tags as a compact JSON array for SwiftData / CloudKit.
    ///
    /// - Throws: ``EventPersistenceCodecError/encodingFailed`` when JSON encoding fails.
    static func encode(_ tags: [EventTag]) throws -> String {
        guard tags.isEmpty == false else {
            return "[]"
        }
        let data: Data
        do {
            data = try JSONEncoder().encode(tags)
        } catch {
            throw EventPersistenceCodecError.encodingFailed
        }
        guard let json = String(data: data, encoding: .utf8) else {
            throw EventPersistenceCodecError.encodingFailed
        }
        return json
    }

    /// Decodes tags from persistence.
    ///
    /// `nil` / empty payloads yield `[]`. Corrupt JSON throws
    /// ``EventPersistenceCodecError/decodingFailed``.
    static func decode(_ rawValue: String?) throws -> [EventTag] {
        guard let rawValue else {
            return []
        }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return []
        }
        guard let data = trimmed.data(using: .utf8) else {
            throw EventPersistenceCodecError.decodingFailed
        }
        do {
            return try JSONDecoder().decode([EventTag].self, from: data)
        } catch {
            throw EventPersistenceCodecError.decodingFailed
        }
    }
}

//
//  UniverseCategory.swift
//  GalacticCalendar
//

import Foundation

/// Classification for a Universe Message.
///
/// Each catalog message belongs to exactly one selectable category.
/// Legacy persisted raw values are resolved via ``resolve(_:)`` without
/// changing the daily selection algorithm in ``UniverseMessageEngine``.
enum UniverseCategory: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    // MARK: - Cases (Sprint 4.6)

    /// Motivación.
    case motivation

    /// Productividad.
    case productivity

    /// Calma.
    case calm

    /// Reflexión.
    case reflection

    /// Gratitud.
    case gratitude

    /// Relaciones.
    case relationships

    /// Éxito.
    case success

    /// Crecimiento personal.
    case personalGrowth

    // MARK: - Identifiable

    /// Stable identifier matching the persistence raw value.
    var id: String { rawValue }

    // MARK: - Selection

    /// Categories shown in the History horizontal selector (ordered).
    static var selectableCases: [UniverseCategory] {
        [
            .motivation,
            .productivity,
            .calm,
            .reflection,
            .gratitude,
            .relationships,
            .success,
            .personalGrowth
        ]
    }

    // MARK: - Legacy Resolution

    /// Resolves a persisted raw value into a category.
    ///
    /// - Returns: `nil` when the value is empty or unknown (treated as uncategorized
    ///   for History filtering). Legacy `inspiration` / `wonder` map to current cases.
    static func resolve(_ rawValue: String?) -> UniverseCategory? {
        guard let rawValue else {
            return nil
        }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return nil
        }
        if let match = UniverseCategory(rawValue: trimmed) {
            return match
        }
        switch trimmed {
        case "inspiration":
            return .motivation
        case "wonder":
            return .calm
        default:
            return nil
        }
    }
}

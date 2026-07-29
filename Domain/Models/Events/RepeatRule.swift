//
//  RepeatRule.swift
//  GalacticCalendar
//

import Foundation

/// Predefined recurrence frequencies persisted with CloudKit-friendly raw values.
///
/// Raw strings remain stable so SwiftData / CloudKit sync can round-trip safely.
enum RepeatFrequency: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    // MARK: - Cases

    /// No recurrence.
    case none

    /// Repeats every day.
    case daily

    /// Repeats every week.
    case weekly

    /// Repeats every month.
    case monthly

    /// Repeats every year.
    case yearly

    // MARK: - Identifiable

    /// Stable identifier matching the persistence raw value.
    var id: String { rawValue }

    // MARK: - Derived

    /// `true` when the frequency produces recurrence.
    var isRecurring: Bool {
        self != .none
    }
}

/// Reserved payload for future custom recurrence rules (RRULE-like).
///
/// Not expanded into occurrences yet. Stored only when a custom rule is present.
struct RepeatCustomConfiguration: Codable, Hashable, Sendable, Equatable {

    // MARK: - Properties

    /// Opaque vendor-neutral rule payload (for example an RRULE string UTF-8).
    var payload: Data

    // MARK: - Lifecycle

    /// Creates a custom configuration envelope.
    /// - Parameter payload: Encoded custom rule bytes.
    init(payload: Data) {
        self.payload = payload
    }
}

/// Recurrence rule attached to a Galactic Calendar ``Event``.
///
/// ## Current behavior
/// Stores a predefined ``RepeatFrequency`` (none / daily / weekly / monthly / yearly).
/// Occurrences are **not** generated yet — only the rule is persisted and restored.
///
/// ## Future custom rules
/// ``interval``, ``endDate``, and ``customConfiguration`` are reserved extension points.
/// Persistence encoding stays backward-compatible with plain frequency raw values.
struct RepeatRule: Sendable, Hashable, Codable, Equatable, Identifiable {

    // MARK: - Properties

    /// Predefined frequency used by the approved editor selector.
    var frequency: RepeatFrequency

    /// Every *n* periods (days/weeks/…). Defaults to `1`. Reserved for custom rules.
    var interval: Int

    /// Optional inclusive end boundary. `nil` means no end. Reserved for custom rules.
    var endDate: Date?

    /// Optional custom rule envelope. `nil` for predefined frequencies.
    var customConfiguration: RepeatCustomConfiguration?

    // MARK: - Identifiable

    /// Stable identity for SwiftUI lists of selectable presets.
    var id: String {
        if customConfiguration != nil {
            return "custom-\(frequency.rawValue)-\(interval)"
        }
        return "\(frequency.rawValue)-\(interval)"
    }

    // MARK: - Presets

    /// No recurrence.
    static let none = RepeatRule(frequency: .none)

    /// Daily recurrence.
    static let daily = RepeatRule(frequency: .daily)

    /// Weekly recurrence.
    static let weekly = RepeatRule(frequency: .weekly)

    /// Monthly recurrence.
    static let monthly = RepeatRule(frequency: .monthly)

    /// Yearly recurrence.
    static let yearly = RepeatRule(frequency: .yearly)

    /// Presets exposed by the approved event-editor repetition selector.
    ///
    /// Keep this list in sync with the design; do not add custom entries here yet.
    static let editorSelectableRules: [RepeatRule] = [
        .none,
        .daily,
        .weekly,
        .monthly,
        .yearly
    ]

    // MARK: - Lifecycle

    /// Creates a recurrence rule.
    /// - Parameters:
    ///   - frequency: Predefined frequency.
    ///   - interval: Period multiplier. Clamped to at least `1`.
    ///   - endDate: Optional end boundary.
    ///   - customConfiguration: Optional future custom payload.
    init(
        frequency: RepeatFrequency,
        interval: Int = 1,
        endDate: Date? = nil,
        customConfiguration: RepeatCustomConfiguration? = nil
    ) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.endDate = endDate
        self.customConfiguration = customConfiguration
    }

    // MARK: - Derived

    /// `true` when the rule describes a recurring event.
    var isRecurring: Bool {
        frequency.isRecurring || customConfiguration != nil
    }
}

// MARK: - Persistence Codec

extension RepeatRule {

    /// Persistence format version embedded in JSON encodings.
    private static let persistenceVersion = 1

    /// Encodes the rule for the SwiftData / CloudKit string column.
    ///
    /// - Plain frequency raw values (`none`, `daily`, …) when only defaults are set —
    ///   preserves compatibility with existing rows.
    /// - Versioned JSON when interval/endDate/custom fields differ from defaults.
    /// - Returns: Persistence string.
    func encodeForPersistence() -> String {
        let usesDefaults =
            interval == 1
            && endDate == nil
            && customConfiguration == nil

        if usesDefaults {
            return frequency.rawValue
        }

        let envelope = PersistenceEnvelope(
            version: Self.persistenceVersion,
            frequency: frequency.rawValue,
            interval: interval,
            endDate: endDate,
            customPayload: customConfiguration?.payload
        )

        do {
            let data = try JSONEncoder().encode(envelope)
            if let json = String(data: data, encoding: .utf8) {
                return json
            }
            return frequency.rawValue
        } catch {
            return frequency.rawValue
        }
    }

    /// Decodes a rule from the SwiftData / CloudKit string column.
    ///
    /// Accepts legacy plain frequency strings and versioned JSON envelopes.
    /// - Parameter rawValue: Stored persistence string.
    /// - Returns: Decoded rule, or ``RepeatRule/none`` when decoding fails.
    static func decodeFromPersistence(_ rawValue: String) -> RepeatRule {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return .none
        }

        if let frequency = RepeatFrequency(rawValue: trimmed) {
            return RepeatRule(frequency: frequency)
        }

        guard let data = trimmed.data(using: .utf8) else {
            return .none
        }

        let envelope: PersistenceEnvelope
        do {
            envelope = try JSONDecoder().decode(PersistenceEnvelope.self, from: data)
        } catch {
            return .none
        }

        guard let frequency = RepeatFrequency(rawValue: envelope.frequency) else {
            return .none
        }

        let custom: RepeatCustomConfiguration?
        if let payload = envelope.customPayload {
            custom = RepeatCustomConfiguration(payload: payload)
        } else {
            custom = nil
        }

        return RepeatRule(
            frequency: frequency,
            interval: envelope.interval,
            endDate: envelope.endDate,
            customConfiguration: custom
        )
    }
}

// MARK: - Persistence Envelope

extension RepeatRule {

    /// Versioned JSON envelope for non-default recurrence fields.
    ///
    /// Kept fileprivate to the persistence codec so CloudKit sync can evolve safely.
    fileprivate struct PersistenceEnvelope: Codable, Equatable, Sendable {
        var version: Int
        var frequency: String
        var interval: Int
        var endDate: Date?
        var customPayload: Data?
    }
}

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

    /// Repeats every two weeks.
    case biweekly

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
/// ## Persistence vs engine (intentional dual stack)
/// - **Persist** this type (`RepeatFrequency.none`, SwiftData / CloudKit strings).
/// - **Expand** via ``asRecurrenceRule`` → ``RecurrenceRule`` / ``RecurrenceEngine``.
/// Do not merge the models: tokens differ (`none` vs `never`) and must stay stable.
///
/// ## Behavior
/// Persisted on ``EventEntity/repeatRuleRawValue``. Expanded dynamically by
/// ``RecurrenceEngine`` via ``asRecurrenceRule`` — no physical occurrence rows.
///
/// ## Compatibility
/// Plain frequency strings (`none`, `daily`, …) remain valid. Versioned JSON
/// carries interval, end date, and occurrence count.
struct RepeatRule: Sendable, Hashable, Codable, Equatable, Identifiable {

    // MARK: - Properties

    /// Predefined frequency used by the approved editor selector.
    var frequency: RepeatFrequency

    /// Every *n* periods (days/weeks/…). Defaults to `1`.
    var interval: Int

    /// Optional inclusive end boundary by date. `nil` means no date end.
    var endDate: Date?

    /// Optional end after N occurrences (master start counts as 1). `nil` = no count end.
    var occurrenceCount: Int?

    /// Optional custom rule envelope. `nil` for predefined frequencies.
    var customConfiguration: RepeatCustomConfiguration?

    // MARK: - Identifiable

    /// Stable identity for SwiftUI lists of selectable presets.
    var id: String {
        if customConfiguration != nil {
            return "custom-\(frequency.rawValue)-\(interval)"
        }
        return "\(frequency.rawValue)-\(interval)-\(occurrenceCount ?? 0)"
    }

    // MARK: - Presets

    /// No recurrence.
    static let none = RepeatRule(frequency: .none)

    /// Daily recurrence.
    static let daily = RepeatRule(frequency: .daily)

    /// Weekly recurrence.
    static let weekly = RepeatRule(frequency: .weekly)

    /// Every two weeks.
    static let biweekly = RepeatRule(frequency: .biweekly)

    /// Monthly recurrence.
    static let monthly = RepeatRule(frequency: .monthly)

    /// Yearly recurrence.
    static let yearly = RepeatRule(frequency: .yearly)

    /// Presets exposed by the approved event-editor repetition selector.
    static let editorSelectableRules: [RepeatRule] = [
        .none,
        .daily,
        .weekly,
        .biweekly,
        .monthly,
        .yearly
    ]

    // MARK: - Lifecycle

    /// Creates a recurrence rule.
    /// - Parameters:
    ///   - frequency: Predefined frequency.
    ///   - interval: Period multiplier. Clamped to at least `1`.
    ///   - endDate: Optional end-by-date boundary.
    ///   - occurrenceCount: Optional end-after-N boundary.
    ///   - customConfiguration: Optional future custom payload.
    init(
        frequency: RepeatFrequency,
        interval: Int = 1,
        endDate: Date? = nil,
        occurrenceCount: Int? = nil,
        customConfiguration: RepeatCustomConfiguration? = nil
    ) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.endDate = endDate
        if let occurrenceCount {
            self.occurrenceCount = max(1, occurrenceCount)
        } else {
            self.occurrenceCount = nil
        }
        self.customConfiguration = customConfiguration
    }

    // MARK: - Derived

    /// `true` when the rule describes a recurring event.
    var isRecurring: Bool {
        frequency.isRecurring || customConfiguration != nil
    }

    /// Canonical recurrence model for ``RecurrenceEngine``.
    var asRecurrenceRule: RecurrenceRule {
        let frequency: RecurrenceFrequency
        switch self.frequency {
        case .none: frequency = .never
        case .daily: frequency = .daily
        case .weekly: frequency = .weekly
        case .biweekly: frequency = .biweekly
        case .monthly: frequency = .monthly
        case .yearly: frequency = .yearly
        }

        let end: RecurrenceEndRule
        if let occurrenceCount {
            end = .after(count: occurrenceCount)
        } else if let endDate {
            end = .onDate(endDate)
        } else {
            end = .never
        }

        return RecurrenceRule(
            frequency: frequency,
            interval: interval,
            end: end,
            byWeekdays: [],
            excludedDates: [],
            customPayload: customConfiguration?.payload
        )
    }
}

// MARK: - Persistence Codec

extension RepeatRule {

    /// Persistence format version embedded in JSON encodings.
    private static let persistenceVersion = 2

    /// Encodes the rule for the SwiftData / CloudKit string column.
    ///
    /// - Plain frequency raw values when only defaults are set.
    /// - Versioned JSON when interval / end / count / custom differ from defaults.
    /// - Throws ``EventPersistenceCodecError/encodingFailed`` instead of dropping fields.
    func encodeForPersistence() throws -> String {
        let usesDefaults =
            interval == 1
            && endDate == nil
            && occurrenceCount == nil
            && customConfiguration == nil

        if usesDefaults {
            return frequency.rawValue
        }

        let envelope = PersistenceEnvelope(
            version: Self.persistenceVersion,
            frequency: frequency.rawValue,
            interval: interval,
            endDate: endDate,
            occurrenceCount: occurrenceCount,
            customPayload: customConfiguration?.payload
        )

        let data: Data
        do {
            data = try JSONEncoder().encode(envelope)
        } catch {
            throw EventPersistenceCodecError.encodingFailed
        }

        guard let json = String(data: data, encoding: .utf8) else {
            throw EventPersistenceCodecError.encodingFailed
        }
        return json
    }

    /// Decodes a rule from the SwiftData / CloudKit string column.
    ///
    /// Empty strings map to ``none``. Corrupt or unknown payloads throw
    /// ``EventPersistenceCodecError/decodingFailed`` (no invented recurrence).
    static func decodeFromPersistence(_ rawValue: String) throws -> RepeatRule {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return .none
        }

        if let frequency = RepeatFrequency(rawValue: trimmed) {
            return RepeatRule(frequency: frequency)
        }

        guard let data = trimmed.data(using: .utf8) else {
            throw EventPersistenceCodecError.decodingFailed
        }

        let envelope: PersistenceEnvelope
        do {
            envelope = try JSONDecoder().decode(PersistenceEnvelope.self, from: data)
        } catch {
            throw EventPersistenceCodecError.decodingFailed
        }

        guard let frequency = RepeatFrequency(rawValue: envelope.frequency) else {
            throw EventPersistenceCodecError.decodingFailed
        }

        let custom: RepeatCustomConfiguration?
        if let payload = envelope.customPayload {
            custom = RepeatCustomConfiguration(payload: payload)
        } else {
            custom = nil
        }

        return RepeatRule(
            frequency: frequency,
            interval: max(1, envelope.interval),
            endDate: envelope.endDate,
            occurrenceCount: envelope.occurrenceCount,
            customConfiguration: custom
        )
    }
}

// MARK: - Persistence Envelope

extension RepeatRule {

    /// Versioned JSON envelope for non-default recurrence fields.
    fileprivate struct PersistenceEnvelope: Codable, Equatable, Sendable {
        var version: Int
        var frequency: String
        var interval: Int
        var endDate: Date?
        var occurrenceCount: Int?
        var customPayload: Data?
    }
}

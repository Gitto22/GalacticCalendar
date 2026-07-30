//
//  StorageAvailability.swift
//  GalacticCalendar
//

import Foundation

/// Global local-store availability for write gating.
///
/// ## Contract
/// - ``available`` — disk SwiftData store is open; reads and writes allowed.
/// - ``unavailable`` — store failed to open; writes must be refused; safe reads may return empty.
/// - ``recovering`` — transient state while a reopen attempt is in progress (no writes).
enum StorageAvailability: Equatable, Sendable {

    // MARK: - Cases

    /// Persistent store is open and writable.
    case available

    /// Persistent store could not be opened. Writes are forbidden.
    case unavailable

    /// A recovery / reopen attempt is running. Writes remain forbidden.
    case recovering

    // MARK: - Derived

    /// `true` when create / update / delete may proceed.
    var allowsWrites: Bool {
        self == .available
    }

    /// `true` when empty or catalog reads are considered safe (never invent persisted data).
    var allowsSafeReads: Bool {
        switch self {
        case .available, .unavailable, .recovering:
            return true
        }
    }
}

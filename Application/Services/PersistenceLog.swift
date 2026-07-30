//
//  PersistenceLog.swift
//  GalacticCalendar
//

import Foundation
import os

/// Structured logging for persistence / store lifecycle (os.Logger).
///
/// There was no prior app logging façade; this is the Persistence-scoped logger
/// used to surface store-open failures that must never be silent.
enum PersistenceLog {

    // MARK: - Logger

    private static let logger = Logger(
        subsystem: "com.albancal.GalacticCalendar",
        category: "Persistence"
    )

    // MARK: - Events

    /// Logs a hard failure opening the on-disk SwiftData store.
    static func storeOpenFailed(_ error: Error) {
        logger.error("SwiftData store failed to open: \(String(describing: error), privacy: .public)")
    }

    /// Logs that the app entered non-writable storage mode.
    static func storageUnavailableEntered() {
        logger.error("Storage availability → unavailable; writes are blocked")
    }

    /// Logs a recovery attempt result.
    static func storageRecovery(succeeded: Bool) {
        if succeeded {
            logger.info("Storage recovery succeeded; writes re-enabled")
        } else {
            logger.error("Storage recovery failed; writes remain blocked")
        }
    }

    /// Logs a write rejected because storage is not available.
    static func writeBlocked(operation: String) {
        logger.error("Write blocked (\(operation, privacy: .public)): storage not available")
    }
}

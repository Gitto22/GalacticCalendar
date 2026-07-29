//
//  EventRepositoryError.swift
//  GalacticCalendar
//

import Foundation

/// Errors produced by ``EventRepositoryProtocol`` implementations.
///
/// Lives in Domain so Application can map failures without depending on Data.
enum EventRepositoryError: Error, Equatable, Sendable {

    // MARK: - Cases

    /// No persistence entity exists for the requested identifier.
    case notFound(UUID)

    /// A save operation failed.
    case saveFailed
}

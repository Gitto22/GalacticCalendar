//
//  EventPersistenceCodecError.swift
//  GalacticCalendar
//

import Foundation

/// Failures while encoding or decoding event persistence payloads.
enum EventPersistenceCodecError: Error, Equatable, Sendable {

    // MARK: - Cases

    /// JSON or string encoding failed without a safe representation.
    case encodingFailed

    /// Persisted payload could not be decoded without inventing data.
    case decodingFailed
}

//
//  FeatureFlag.swift
//  GalacticCalendar
//

import Foundation

/// Identifiers for progressive capability rollout across Galactic Calendar.
enum FeatureFlag: String, Sendable, CaseIterable, Identifiable {

    // MARK: - Cases

    /// Enables CloudKit synchronization when implemented.
    case cloudKitSync

    /// Enables WidgetKit surfaces when implemented.
    case widgets

    /// Enables Apple Watch companion work when implemented.
    case appleWatch

    /// Enables Apple Calendar (EventKit) integration when implemented.
    case eventKit

    /// Enables event sharing when implemented.
    case sharing

    /// Enables Universe Messages when implemented.
    case universeMessages

    /// Enables StoreKit 2 commerce when implemented.
    case storeKit

    /// Enables backup and restore when implemented.
    case backup

    /// Enables statistics when implemented.
    case statistics

    /// Enables additional visual themes when implemented.
    case additionalThemes

    // MARK: - Identifiable

    /// Stable identifier matching the raw flag name.
    var id: String { rawValue }
}

//
//  Typography.swift
//  GalacticCalendar
//

import SwiftUI

/// Text style tokens for Galactic Calendar.
///
/// Views must consume typography exclusively through these tokens.
enum Typography {

    // MARK: - Display

    /// Largest display style for hero-level titles.
    static let display = Font.system(size: 34, weight: .bold, design: .default)

    /// Large title style.
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)

    // MARK: - Titles

    /// Primary title style.
    static let title = Font.system(size: 22, weight: .semibold, design: .default)

    /// Secondary title style.
    static let title2 = Font.system(size: 20, weight: .semibold, design: .default)

    /// Tertiary title style.
    static let title3 = Font.system(size: 18, weight: .semibold, design: .default)

    // MARK: - Body

    /// Emphasized headline style.
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)

    /// Standard body style.
    static let body = Font.system(size: 17, weight: .regular, design: .default)

    /// Callout style for supporting statements.
    static let callout = Font.system(size: 16, weight: .regular, design: .default)

    /// Subheadline style.
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

    // MARK: - Meta

    /// Footnote style for compact metadata.
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)

    /// Caption style.
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Smallest caption style.
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Mono

    /// Monospaced style for numeric emphasis when required.
    static let monospacedDigit = Font.system(size: 17, weight: .medium, design: .monospaced)
}

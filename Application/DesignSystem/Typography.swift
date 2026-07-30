//
//  Typography.swift
//  GalacticCalendar
//

import SwiftUI

/// Text style tokens for Galactic Calendar.
///
/// Views must consume typography exclusively through these tokens.
/// Every token maps to a Dynamic Type ``Font.TextStyle`` (no fixed point sizes)
/// so Accessibility text sizes, iPhone SE, and iPad scale consistently while
/// preserving the approved visual hierarchy.
enum Typography {

    // MARK: - Display

    /// Largest display style for hero-level titles → ``Font/largeTitle``.
    static let display = Font.largeTitle.weight(.bold)

    /// Large title style → ``Font/title`` (Apple large title hierarchy step).
    static let largeTitle = Font.title.weight(.bold)

    // MARK: - Titles

    /// Primary title style → ``Font/title2``.
    static let title = Font.title2.weight(.semibold)

    /// Secondary title style → ``Font/title3``.
    static let title2 = Font.title3.weight(.semibold)

    /// Tertiary title / icon emphasis → ``Font/headline``.
    static let title3 = Font.headline

    // MARK: - Body

    /// Emphasized headline style → ``Font/headline``.
    static let headline = Font.headline

    /// Standard body style → ``Font/body``.
    static let body = Font.body

    /// Callout style for supporting statements → ``Font/callout``.
    static let callout = Font.callout

    /// Subheadline style → ``Font/subheadline``.
    static let subheadline = Font.subheadline

    // MARK: - Meta

    /// Footnote style for compact metadata → ``Font/footnote``.
    static let footnote = Font.footnote

    /// Caption style → ``Font/caption``.
    static let caption = Font.caption

    /// Smallest caption style → ``Font/caption2``.
    static let caption2 = Font.caption2

    // MARK: - Mono

    /// Monospaced digit emphasis → body text style + monospaced digits.
    static let monospacedDigit = Font.body.weight(.medium).monospacedDigit()
}

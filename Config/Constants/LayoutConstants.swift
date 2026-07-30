//
//  LayoutConstants.swift
//  GalacticCalendar
//

import CoreGraphics

/// Layout constants aligned with the approved visual identity.
enum LayoutConstants {

    // MARK: - Text

    /// Minimum scale factor for single-line titles that must remain readable.
    static let singleLineMinimumScale: CGFloat = 0.75

    // MARK: - Home Badge

    /// Diameter for the Universe Message inspiration badge.
    static let inspirationBadgeSize: CGFloat = Spacing.xl

    // MARK: - Calendar

    /// Minimum height for a day cell in the monthly grid.
    static let dayCellMinHeight: CGFloat = Spacing.xxl

    /// Diameter for event indicator dots.
    static let eventIndicatorSize: CGFloat = Spacing.xxs

    /// Stroke width for the current/selected day highlight.
    static let dayHighlightStroke: CGFloat = Spacing.headerControlStroke

    /// Stroke width for the default day cell border.
    static let dayCellBorderStroke: CGFloat = Spacing.hairline

    /// Minimum day-cell height on compact width devices.
    static let dayCellMinHeightCompact: CGFloat = Spacing.xxl

    /// Minimum day-cell height on regular width devices.
    static let dayCellMinHeightRegular: CGFloat = Spacing.xxxl

    /// Diameter for selectable event color dots in the editor.
    static let eventColorDotSize: CGFloat = Spacing.sm

    /// Minimum height for the event description editor.
    static let eventDescriptionMinHeight: CGFloat = Spacing.xxxl + Spacing.xl
}

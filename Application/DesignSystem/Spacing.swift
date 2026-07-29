//
//  Spacing.swift
//  GalacticCalendar
//

import CoreGraphics

/// Spacing and corner-radius tokens for Galactic Calendar.
///
/// Views must consume spacing exclusively through these tokens.
enum Spacing {

    // MARK: - Scale

    /// 2 pt spacing.
    static let xxxs: CGFloat = 2

    /// 4 pt spacing.
    static let xxs: CGFloat = 4

    /// 8 pt spacing.
    static let xs: CGFloat = 8

    /// 12 pt spacing.
    static let sm: CGFloat = 12

    /// 16 pt spacing.
    static let md: CGFloat = 16

    /// 24 pt spacing.
    static let lg: CGFloat = 24

    /// 32 pt spacing.
    static let xl: CGFloat = 32

    /// 48 pt spacing.
    static let xxl: CGFloat = 48

    /// 64 pt spacing.
    static let xxxl: CGFloat = 64

    // MARK: - Layout

    /// Standard horizontal page inset.
    static let pageHorizontal: CGFloat = md

    /// Standard vertical page inset.
    static let pageVertical: CGFloat = md

    /// Stack spacing for tightly related elements.
    static let stackTight: CGFloat = xs

    /// Stack spacing for default groupings.
    static let stackRegular: CGFloat = sm

    /// Stack spacing for loose groupings.
    static let stackLoose: CGFloat = md

    // MARK: - Radius

    /// Corner radius tokens shared across surfaces.
    enum Radius {

        /// 8 pt corner radius.
        static let sm: CGFloat = 8

        /// 12 pt corner radius.
        static let md: CGFloat = 12

        /// 16 pt corner radius.
        static let lg: CGFloat = 16

        /// 24 pt corner radius.
        static let xl: CGFloat = 24
    }
}

//
//  MonthContrastProfile.swift
//  GalacticCalendar
//

import SwiftUI

/// Per-month readability treatment for full-bleed monthly imagery.
///
/// Profiles are calibrated from measured luminance peaks (p99) of the
/// approved month assets so white / accent chrome stays legible without
/// changing layout or approved surface treatments (glass, day cells, cards).
enum MonthContrastProfile: String, Sendable, CaseIterable, Equatable, Identifiable {

    // MARK: - Cases

    /// Darker months — light base scrim + soft top gradient.
    case standard

    /// Moderate bright peaks — stronger scrim + mid-band support.
    case elevated

    /// Bright nebula / planet peaks — strongest scrim + vertical gradient.
    case strong

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Scrim

    /// Uniform black scrim opacity layered above the month image.
    var baseScrimOpacity: Double {
        switch self {
        case .standard: 0.28
        case .elevated: 0.40
        case .strong: 0.52
        }
    }

    /// Extra darkening at the top (header / week labels).
    var topGradientOpacity: Double {
        switch self {
        case .standard: 0.18
        case .elevated: 0.28
        case .strong: 0.38
        }
    }

    /// Extra darkening through the calendar / card band.
    var midGradientOpacity: Double {
        switch self {
        case .standard: 0.08
        case .elevated: 0.18
        case .strong: 0.28
        }
    }

    /// Soft bottom fade so the image remains present under lower chrome.
    var bottomGradientOpacity: Double {
        switch self {
        case .standard: 0.10
        case .elevated: 0.14
        case .strong: 0.20
        }
    }
}

// MARK: - Month Asset Mapping

extension MonthBackgroundAsset {

    /// Contrast profile derived from asset luminance peaks (PB-04).
    ///
    /// - Standard: February, September, November  
    /// - Elevated: April, May, July  
    /// - Strong: January, March, June, August, October, December
    var contrastProfile: MonthContrastProfile {
        switch self {
        case .february, .september, .november:
            .standard
        case .april, .may, .july:
            .elevated
        case .january, .march, .june, .august, .october, .december:
            .strong
        }
    }
}

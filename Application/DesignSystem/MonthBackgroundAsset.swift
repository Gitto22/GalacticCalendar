//
//  MonthBackgroundAsset.swift
//  GalacticCalendar
//

import Foundation

/// Asset names for the twelve approved monthly backgrounds in `Assets/Months`.
enum MonthBackgroundAsset: Int, CaseIterable, Sendable, Identifiable {

    // MARK: - Cases

    case january = 1
    case february
    case march
    case april
    case may
    case june
    case july
    case august
    case september
    case october
    case november
    case december

    // MARK: - Identifiable

    /// Stable identifier matching the month number.
    var id: Int { rawValue }

    // MARK: - Assets

    /// Imageset name under `Assets/Months`.
    var imageName: String {
        switch self {
        case .january: "January"
        case .february: "February"
        case .march: "March"
        case .april: "April"
        case .may: "May"
        case .june: "June"
        case .july: "July"
        case .august: "August"
        case .september: "September"
        case .october: "October"
        case .november: "November"
        case .december: "December"
        }
    }

    // MARK: - Factory

    /// Resolves a monthly background asset from a calendar month number.
    /// - Parameter monthNumber: Month number in `1...12`.
    /// - Returns: Matching asset, if the month number is valid.
    static func asset(for monthNumber: Int) -> MonthBackgroundAsset? {
        MonthBackgroundAsset(rawValue: monthNumber)
    }
}

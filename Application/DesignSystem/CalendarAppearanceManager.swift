//
//  CalendarAppearanceManager.swift
//  GalacticCalendar
//

import Foundation
import SwiftUI

/// Owns calendar-facing visual state: visible month/year, monthly background,
/// contrast treatment, and localized title strings for Home chrome.
///
/// Extracted from ``ThemeManager`` (PB-05.1) so theme packs / color scheme stay
/// separate from calendar presentation. Behavior matches the previous
/// ThemeManager month/background API.
@MainActor
@Observable
final class CalendarAppearanceManager {

    // MARK: - Properties

    /// Optional month override when navigation changes the visible month.
    ///
    /// When `nil`, the manager uses the device's current month.
    var displayedMonthOverride: Int?

    /// Optional year override paired with ``displayedMonthOverride``.
    ///
    /// When `nil`, the manager uses the device's current year.
    var displayedYearOverride: Int?

    /// Calendar used for localized month/year formatting.
    private let calendar: Calendar

    /// Formatter used to produce localized month names.
    private let monthNameFormatter: DateFormatter

    /// Formatter used to produce localized year text.
    private let yearFormatter: DateFormatter

    // MARK: - Lifecycle

    /// Creates a calendar appearance manager.
    /// - Parameter calendar: Calendar used for formatting (month detection uses `Calendar.current`).
    init(calendar: Calendar = .current) {
        self.calendar = calendar

        let monthFormatter = DateFormatter()
        monthFormatter.calendar = calendar
        monthFormatter.locale = .autoupdatingCurrent
        monthFormatter.setLocalizedDateFormatFromTemplate("MMMM")
        self.monthNameFormatter = monthFormatter

        let yearFormatter = DateFormatter()
        yearFormatter.calendar = calendar
        yearFormatter.locale = .autoupdatingCurrent
        yearFormatter.setLocalizedDateFormatFromTemplate("y")
        self.yearFormatter = yearFormatter
    }

    // MARK: - Month Detection

    /// Returns the device's current calendar month number (`1...12`).
    func currentMonth() -> Int {
        Calendar.current.component(.month, from: Date())
    }

    /// Returns the device's current calendar year.
    func currentYear() -> Int {
        Calendar.current.component(.year, from: Date())
    }

    /// Month number currently driving the Home background and header.
    var activeMonthNumber: Int {
        if let displayedMonthOverride,
           MonthBackgroundAsset.asset(for: displayedMonthOverride) != nil {
            return displayedMonthOverride
        }

        return currentMonth()
    }

    /// Year currently driving the Home header.
    var activeYear: Int {
        displayedYearOverride ?? currentYear()
    }

    /// Localized display name for the active month.
    func displayedMonthName() -> String {
        localizedMonthName(for: activeMonthNumber, year: activeYear)
    }

    /// Localized display text for the active year.
    func displayedYearText() -> String {
        localizedYearText(for: activeYear)
    }

    /// Sets the visible month/year for Home title and background.
    ///
    /// Called by Home month navigation after ``CalendarGridViewModel`` changes.
    /// - Parameters:
    ///   - month: Month number in `1...12`.
    ///   - year: Year value associated with the month.
    func prepareDisplayedMonth(_ month: Int, year: Int) {
        guard MonthBackgroundAsset.asset(for: month) != nil else {
            return
        }

        displayedMonthOverride = month
        displayedYearOverride = year
    }

    /// Active monthly background asset.
    var activeMonthBackground: MonthBackgroundAsset {
        MonthBackgroundAsset.asset(for: activeMonthNumber) ?? .january
    }

    // MARK: - Backgrounds

    /// Returns the imageset name for the provided month number.
    /// - Parameter month: Month number in `1...12`.
    /// - Returns: Asset name such as `July`.
    func backgroundAssetName(for month: Int) -> String {
        MonthBackgroundAsset.asset(for: month)?.imageName
            ?? MonthBackgroundAsset.january.imageName
    }

    /// Asset name for the active month background.
    var activeMonthBackgroundName: String {
        backgroundAssetName(for: activeMonthNumber)
    }

    /// Contrast profile for the active month background (PB-04).
    var activeMonthContrastProfile: MonthContrastProfile {
        activeMonthBackground.contrastProfile
    }

    // MARK: - Localization Helpers

    /// Returns a localized month name for the provided month and year.
    private func localizedMonthName(for month: Int, year: Int) -> String {
        var components = DateComponents()
        components.calendar = calendar
        components.year = year
        components.month = month
        components.day = 1

        guard let date = calendar.date(from: components) else {
            return ""
        }

        return monthNameFormatter.string(from: date)
    }

    /// Returns localized year text for the provided year.
    private func localizedYearText(for year: Int) -> String {
        var components = DateComponents()
        components.calendar = calendar
        components.year = year
        components.month = 1
        components.day = 1

        guard let date = calendar.date(from: components) else {
            return ""
        }

        return yearFormatter.string(from: date)
    }
}

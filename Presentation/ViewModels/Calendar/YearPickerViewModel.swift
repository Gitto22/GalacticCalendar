//
//  YearPickerViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Configurable inclusive year range for ``YearPickerViewModel``.
///
/// Widen or narrow bounds without changing picker UI or Home wiring.
struct YearPickerRange: Equatable, Sendable {

    // MARK: - Properties

    /// Inclusive first year.
    let lowerBound: Int

    /// Inclusive last year.
    let upperBound: Int

    // MARK: - Defaults

    /// Shipping default: 2000…2100.
    static let `default` = YearPickerRange(
        lowerBound: CalendarConstants.yearPickerLowerBound,
        upperBound: CalendarConstants.yearPickerUpperBound
    )

    // MARK: - Derived

    /// Ordered years in the range (`lowerBound...upperBound`).
    var years: [Int] {
        guard lowerBound <= upperBound else {
            return []
        }
        return Array(lowerBound...upperBound)
    }

    /// Clamps ``year`` into this range.
    func clamping(_ year: Int) -> Int {
        min(max(year, lowerBound), upperBound)
    }

    /// Whether ``year`` lies inside the range.
    func contains(_ year: Int) -> Bool {
        year >= lowerBound && year <= upperBound
    }
}

/// One row in the year selector.
struct YearPickerItem: Identifiable, Equatable, Sendable {

    // MARK: - Properties

    /// Calendar year.
    let year: Int

    /// Localized display text for the year.
    let title: String

    // MARK: - Identifiable

    var id: Int { year }
}

/// Presentation model for the year selector.
///
/// Lists years in a configurable ``YearPickerRange`` while keeping the
/// Home month fixed. Home applies the choice via ``CalendarGridViewModel/showMonth``.
@MainActor
@Observable
final class YearPickerViewModel {

    // MARK: - Properties

    /// Month kept constant for this picker session (`1...12`).
    let month: Int

    /// Inclusive year bounds (easy to widen later).
    let range: YearPickerRange

    /// Currently highlighted year.
    private(set) var selectedYear: Int

    /// Ordered year rows for the scrollable list.
    let years: [YearPickerItem]

    /// Calendar used to localize year titles.
    private let calendar: Calendar

    // MARK: - Lifecycle

    /// Creates a year picker for the given visible period.
    /// - Parameters:
    ///   - selectedYear: Year currently shown on Home.
    ///   - month: Month to keep when a year is chosen.
    ///   - range: Inclusive year bounds (default 2000…2100).
    ///   - calendar: Calendar for localization.
    init(
        selectedYear: Int,
        month: Int,
        range: YearPickerRange = .default,
        calendar: Calendar = .current
    ) {
        let clampedMonth = min(max(month, 1), 12)
        self.month = clampedMonth
        self.range = range
        self.calendar = calendar
        self.selectedYear = range.clamping(selectedYear)
        self.years = Self.makeYears(range: range, calendar: calendar)
    }

    // MARK: - Intents

    /// Selects a year for Home to apply.
    /// - Parameter year: Full year value.
    /// - Returns: `true` when the year is inside ``range``.
    @discardableResult
    func selectYear(_ year: Int) -> Bool {
        guard range.contains(year) else {
            return false
        }
        selectedYear = year
        return true
    }

    /// Whether ``year`` is the active selection.
    func isSelected(_ year: Int) -> Bool {
        year == selectedYear
    }

    // MARK: - Private

    /// Builds localized titles for every year in ``range``.
    private static func makeYears(
        range: YearPickerRange,
        calendar: Calendar
    ) -> [YearPickerItem] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("y")

        return range.years.compactMap { year in
            var components = DateComponents()
            components.calendar = calendar
            components.year = year
            components.month = 1
            components.day = 1
            guard let date = calendar.date(from: components) else {
                return nil
            }
            return YearPickerItem(
                year: year,
                title: formatter.string(from: date)
            )
        }
    }
}

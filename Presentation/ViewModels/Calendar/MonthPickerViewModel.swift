//
//  MonthPickerViewModel.swift
//  GalacticCalendar
//

import Foundation

/// One row in the quick month selector.
struct MonthPickerItem: Identifiable, Equatable, Sendable {

    // MARK: - Properties

    /// Month number in `1...12`.
    let month: Int

    /// Localized month display name.
    let title: String

    // MARK: - Identifiable

    var id: Int { month }
}

/// Presentation model for the quick month selector.
///
/// Lists January…December for a fixed year. Selection does not change the year.
/// Home applies the choice to the grid and theme after ``selectMonth(_:)``.
@MainActor
@Observable
final class MonthPickerViewModel {

    // MARK: - Properties

    /// Year kept constant for this picker session.
    let year: Int

    /// Currently highlighted month (`1...12`).
    private(set) var selectedMonth: Int

    /// Ordered month rows (January → December).
    let months: [MonthPickerItem]

    /// Calendar used to build localized titles.
    private let calendar: Calendar

    // MARK: - Lifecycle

    /// Creates a month picker for the given visible period.
    /// - Parameters:
    ///   - selectedMonth: Month currently shown on Home (`1...12`).
    ///   - year: Year to keep when a month is chosen.
    ///   - calendar: Calendar for localization.
    init(
        selectedMonth: Int,
        year: Int,
        calendar: Calendar = .current
    ) {
        let clampedMonth = min(max(selectedMonth, 1), 12)
        self.selectedMonth = clampedMonth
        self.year = year
        self.calendar = calendar
        self.months = Self.makeMonths(year: year, calendar: calendar)
    }

    // MARK: - Intents

    /// Selects a month for Home to apply.
    /// - Parameter month: Month number in `1...12`.
    /// - Returns: `true` when the month is valid and was recorded.
    @discardableResult
    func selectMonth(_ month: Int) -> Bool {
        guard month >= 1, month <= 12 else {
            return false
        }
        selectedMonth = month
        return true
    }

    /// Whether ``month`` is the active selection.
    func isSelected(_ month: Int) -> Bool {
        month == selectedMonth
    }

    // MARK: - Private

    /// Builds localized January…December titles for ``year``.
    private static func makeMonths(year: Int, calendar: Calendar) -> [MonthPickerItem] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMMM")

        return (1...12).compactMap { month in
            var components = DateComponents()
            components.calendar = calendar
            components.year = year
            components.month = month
            components.day = 1
            guard let date = calendar.date(from: components) else {
                return nil
            }
            return MonthPickerItem(
                month: month,
                title: formatter.string(from: date)
            )
        }
    }
}

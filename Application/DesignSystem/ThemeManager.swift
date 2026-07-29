//
//  ThemeManager.swift
//  GalacticCalendar
//

import Foundation
import SwiftUI

/// Contract for visual theme packs.
///
/// Enables future StoreKit-delivered or bundled theme packages
/// without changing call sites that depend on ``ThemeManager``.
protocol ThemePack: Identifiable, Sendable {

    /// Stable theme pack identifier.
    var id: String { get }

    /// User-facing theme pack name.
    var displayName: String { get }
}

/// Default Galactic Calendar theme pack.
struct GalacticDefaultThemePack: ThemePack {

    // MARK: - Properties

    /// Stable identifier for the default pack.
    let id = "galactic.default"

    /// Display name for the default pack.
    let displayName = "Galactic Default"

    // MARK: - Shared

    /// Shared default pack instance.
    static let shared = GalacticDefaultThemePack()
}

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

/// Design System authority for visual theme and monthly backgrounds.
///
/// Detects the current month, resolves the corresponding approved
/// background asset, and manages appearance preferences.
@MainActor
@Observable
final class ThemeManager {

    // MARK: - Properties

    /// Preferred color scheme. `nil` follows the system appearance.
    var preferredColorScheme: ColorScheme?

    /// Identifier of the active theme pack.
    var activeThemePackID: String

    /// Optional month override used when a future calendar module changes visible month.
    ///
    /// When `nil`, the manager uses the device's current month.
    var displayedMonthOverride: Int?

    /// Optional year override paired with ``displayedMonthOverride``.
    ///
    /// When `nil`, the manager uses the device's current year.
    var displayedYearOverride: Int?

    /// Indicates whether additional theme packs may be activated.
    private let allowsAdditionalThemes: Bool

    /// Calendar used for month detection.
    private let calendar: Calendar

    /// Bundled theme packs currently available to the application.
    private let bundledThemePacks: [any ThemePack]

    /// Formatter used to produce localized month names.
    private let monthNameFormatter: DateFormatter

    /// Formatter used to produce localized year text.
    private let yearFormatter: DateFormatter

    // MARK: - Lifecycle

    /// Creates a theme manager.
    /// - Parameters:
    ///   - preferredColorScheme: Initial appearance preference.
    ///   - allowsAdditionalThemes: Whether additional theme packs may be used.
    ///   - calendar: Calendar used to detect the current month.
    ///   - bundledThemePacks: Theme packs shipped with the app.
    init(
        preferredColorScheme: ColorScheme? = nil,
        allowsAdditionalThemes: Bool = false,
        calendar: Calendar = .current,
        bundledThemePacks: [any ThemePack] = [GalacticDefaultThemePack.shared]
    ) {
        self.preferredColorScheme = preferredColorScheme
        self.allowsAdditionalThemes = allowsAdditionalThemes
        self.calendar = calendar
        self.bundledThemePacks = bundledThemePacks
        self.activeThemePackID = GalacticDefaultThemePack.shared.id

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

    /// Current calendar month number in the range `1...12`.
    var currentMonthNumber: Int {
        currentMonth()
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

    /// Prepares a visible month/year for future month navigation.
    ///
    /// Does not perform navigation by itself; call sites will use this
    /// when month changing is implemented.
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

    // MARK: - Localization Helpers

    /// Returns a localized month name for the provided month and year.
    /// - Parameters:
    ///   - month: Month number in `1...12`.
    ///   - year: Year used to build a valid date.
    /// - Returns: Localized month name, or an empty string when invalid.
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
    /// - Parameter year: Year value to format.
    /// - Returns: Localized year text, or an empty string when invalid.
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

    // MARK: - Backgrounds

    /// Returns the imageset name for the provided month number.
    /// - Parameter month: Month number in `1...12`.
    /// - Returns: Asset name such as `July`.
    func backgroundAssetName(for month: Int) -> String {
        MonthBackgroundAsset.asset(for: month)?.imageName
            ?? MonthBackgroundAsset.january.imageName
    }

    /// Returns the imageset name for the device's current month.
    /// - Returns: Asset name under `Assets/Months`.
    func currentBackgroundAsset() -> String {
        backgroundAssetName(for: currentMonth())
    }

    /// Asset name for the active month background.
    var activeMonthBackgroundName: String {
        backgroundAssetName(for: activeMonthNumber)
    }

    /// Returns the asset name for the device's current calendar month.
    /// - Returns: Imageset name such as `July`.
    func currentMonthBackgroundName() -> String {
        currentBackgroundAsset()
    }

    /// Returns the asset name for a specific month number.
    /// - Parameter monthNumber: Month number in `1...12`.
    /// - Returns: Imageset name under `Assets/Months`.
    func monthBackgroundName(for monthNumber: Int) -> String {
        backgroundAssetName(for: monthNumber)
    }

    /// Returns the SwiftUI image for a specific month number.
    /// - Parameter monthNumber: Month number in `1...12`.
    /// - Returns: Image referencing `Assets/Months`.
    func monthBackgroundImage(for monthNumber: Int) -> Image {
        Image(backgroundAssetName(for: monthNumber))
    }

    /// SwiftUI image for the active month background.
    var activeMonthBackgroundImage: Image {
        Image(activeMonthBackgroundName)
    }

    // MARK: - Appearance

    /// Resets appearance to the system color scheme.
    func useSystemAppearance() {
        preferredColorScheme = nil
    }

    /// Applies a light appearance preference.
    func useLightAppearance() {
        preferredColorScheme = .light
    }

    /// Applies a dark appearance preference.
    func useDarkAppearance() {
        preferredColorScheme = .dark
    }

    // MARK: - Theme Packs

    /// Theme packs available to the application right now.
    var availableThemePacks: [any ThemePack] {
        if allowsAdditionalThemes {
            return bundledThemePacks
        }

        return bundledThemePacks.filter { $0.id == GalacticDefaultThemePack.shared.id }
    }

    /// Currently selected theme pack, if available.
    var activeThemePack: (any ThemePack)? {
        availableThemePacks.first { $0.id == activeThemePackID }
    }

    /// Selects a theme pack when additional themes are permitted.
    /// - Parameter pack: Theme pack to activate.
    /// - Returns: `true` when the pack was activated.
    @discardableResult
    func selectThemePack(_ pack: any ThemePack) -> Bool {
        guard allowsAdditionalThemes else {
            return false
        }

        guard availableThemePacks.contains(where: { $0.id == pack.id }) else {
            return false
        }

        activeThemePackID = pack.id
        return true
    }

    /// Reports whether additional themes are currently allowed by configuration.
    var canUseAdditionalThemes: Bool {
        allowsAdditionalThemes
    }
}

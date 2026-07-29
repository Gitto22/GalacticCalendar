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

    /// Indicates whether additional theme packs may be activated.
    private let allowsAdditionalThemes: Bool

    /// Calendar used for month detection.
    private let calendar: Calendar

    /// Bundled theme packs currently available to the application.
    private let bundledThemePacks: [any ThemePack]

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
    }

    // MARK: - Month Detection

    /// Returns the device's current calendar month number (`1...12`).
    func currentMonth() -> Int {
        Calendar.current.component(.month, from: Date())
    }

    /// Current calendar month number in the range `1...12`.
    var currentMonthNumber: Int {
        currentMonth()
    }

    /// Month number currently driving the Home background.
    var activeMonthNumber: Int {
        if let displayedMonthOverride,
           MonthBackgroundAsset.asset(for: displayedMonthOverride) != nil {
            return displayedMonthOverride
        }

        return currentMonth()
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

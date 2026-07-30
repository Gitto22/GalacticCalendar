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

/// Design System authority for **theming** only (PB-05.1).
///
/// ## Owns (runtime)
/// - Light / dark / system via ``preferredColorScheme``
/// - Theme-pack selection (``ThemePack`` / ``GalacticDefaultThemePack``)
///
/// ## Governs (static Design System surfaces — not calendar state)
/// Views consume tokens exclusively through:
/// ``ColorPalette``, ``Typography``, ``Spacing``, ``Shadows``, ``GlassEffect``.
///
/// ## Does not own
/// Visible month/year, monthly background assets, contrast scrims, or month
/// transitions — those live in ``CalendarAppearanceManager`` + ``MonthBackgroundView``.
@MainActor
@Observable
final class ThemeManager {

    // MARK: - Properties

    /// Preferred color scheme. `nil` follows the system appearance.
    var preferredColorScheme: ColorScheme?

    /// Identifier of the active theme pack.
    var activeThemePackID: String

    /// Indicates whether additional theme packs may be activated.
    private let allowsAdditionalThemes: Bool

    /// Bundled theme packs currently available to the application.
    private let bundledThemePacks: [any ThemePack]

    // MARK: - Lifecycle

    /// Creates a theme manager.
    /// - Parameters:
    ///   - preferredColorScheme: Initial appearance preference.
    ///   - allowsAdditionalThemes: Whether additional theme packs may be used.
    ///   - bundledThemePacks: Theme packs shipped with the app.
    init(
        preferredColorScheme: ColorScheme? = nil,
        allowsAdditionalThemes: Bool = false,
        bundledThemePacks: [any ThemePack] = [GalacticDefaultThemePack.shared]
    ) {
        self.preferredColorScheme = preferredColorScheme
        self.allowsAdditionalThemes = allowsAdditionalThemes
        self.bundledThemePacks = bundledThemePacks
        self.activeThemePackID = GalacticDefaultThemePack.shared.id
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

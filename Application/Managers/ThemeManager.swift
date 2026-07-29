//
//  ThemeManager.swift
//  GalacticCalendar
//

import Foundation
import SwiftUI

/// Application-level manager for appearance preferences.
///
/// Preserves the approved visual identity. Additional themes remain
/// gated and unimplemented.
@MainActor
@Observable
final class ThemeManager {

    // MARK: - Properties

    /// Preferred color scheme. `nil` follows the system appearance.
    var preferredColorScheme: ColorScheme?

    /// Indicates whether additional themes may be considered later.
    private let allowsAdditionalThemes: Bool

    // MARK: - Lifecycle

    /// Creates a theme manager.
    /// - Parameters:
    ///   - preferredColorScheme: Initial appearance preference.
    ///   - allowsAdditionalThemes: Whether the additional-themes flag is enabled.
    init(
        preferredColorScheme: ColorScheme? = nil,
        allowsAdditionalThemes: Bool = false
    ) {
        self.preferredColorScheme = preferredColorScheme
        self.allowsAdditionalThemes = allowsAdditionalThemes
        // TODO: Load persisted appearance preference when settings storage is introduced.
    }

    // MARK: - Appearance

    /// Resets appearance to the system color scheme.
    func useSystemAppearance() {
        preferredColorScheme = nil
        // TODO: Persist the system preference when settings storage is introduced.
    }

    /// Applies a light appearance preference.
    func useLightAppearance() {
        preferredColorScheme = .light
        // TODO: Persist the light preference when settings storage is introduced.
    }

    /// Applies a dark appearance preference.
    func useDarkAppearance() {
        preferredColorScheme = .dark
        // TODO: Persist the dark preference when settings storage is introduced.
    }

    // MARK: - Future Themes

    /// Reports whether additional themes are currently allowed by configuration.
    var canUseAdditionalThemes: Bool {
        allowsAdditionalThemes
    }

    // TODO: Coordinate month background selection with Assets/Months when Home binds the visible month.
    // TODO: Introduce additional theme catalogs only when FeatureFlag.additionalThemes is enabled.
}

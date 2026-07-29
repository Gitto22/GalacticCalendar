//
//  ThemeManager.swift
//  GalacticCalendar
//

import Foundation
import SwiftUI

/// Manages appearance preferences for the approved visual identity.
///
/// Does not introduce new themes. Additional themes remain gated behind
/// ``FeatureFlag/additionalThemes`` until explicitly implemented.
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

    // MARK: - Future Themes

    /// Reports whether additional themes are currently allowed by configuration.
    var canUseAdditionalThemes: Bool {
        allowsAdditionalThemes
    }
}

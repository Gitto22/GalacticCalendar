//
//  ThemeManagerTests.swift
//  GalacticCalendar
//

import XCTest
import SwiftUI
@testable import GalacticCalendar

/// PB-05.1 — ThemeManager owns appearance / theme packs only.
final class ThemeManagerTests: XCTestCase {

    func testPreferredColorSchemeDefaultsToSystem() {
        let manager = ThemeManager()
        XCTAssertNil(manager.preferredColorScheme)
    }

    func testPreferredColorSchemeCanBeSet() {
        let manager = ThemeManager(preferredColorScheme: .dark)
        XCTAssertEqual(manager.preferredColorScheme, .dark)
        manager.preferredColorScheme = .light
        XCTAssertEqual(manager.preferredColorScheme, .light)
    }

    func testDefaultThemePackIsActive() {
        let manager = ThemeManager()
        XCTAssertEqual(manager.activeThemePackID, GalacticDefaultThemePack.shared.id)
        XCTAssertEqual(manager.activeThemePack?.id, GalacticDefaultThemePack.shared.id)
        XCTAssertFalse(manager.canUseAdditionalThemes)
    }

    func testSelectThemePackRejectedWhenAdditionalThemesDisabled() {
        let pack = GalacticDefaultThemePack.shared
        let manager = ThemeManager(allowsAdditionalThemes: false)
        XCTAssertFalse(manager.selectThemePack(pack))
    }

    func testSelectThemePackAllowedWhenFlagEnabled() {
        let pack = GalacticDefaultThemePack.shared
        let manager = ThemeManager(allowsAdditionalThemes: true)
        XCTAssertTrue(manager.selectThemePack(pack))
        XCTAssertEqual(manager.activeThemePackID, pack.id)
        XCTAssertEqual(manager.availableThemePacks.count, 1)
    }
}

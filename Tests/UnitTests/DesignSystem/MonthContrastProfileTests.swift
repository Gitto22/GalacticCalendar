//
//  MonthContrastProfileTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Sprint PB-04 — Contrast profiles for monthly backgrounds.
final class MonthContrastProfileTests: XCTestCase {

    func testEveryMonthMapsToAProfile() {
        for asset in MonthBackgroundAsset.allCases {
            XCTAssertNotNil(asset.contrastProfile)
        }
    }

    func testStandardMonthsUseLightestScrim() {
        XCTAssertEqual(MonthBackgroundAsset.february.contrastProfile, .standard)
        XCTAssertEqual(MonthBackgroundAsset.september.contrastProfile, .standard)
        XCTAssertEqual(MonthBackgroundAsset.november.contrastProfile, .standard)
        XCTAssertEqual(MonthContrastProfile.standard.baseScrimOpacity, 0.28, accuracy: 0.001)
    }

    func testElevatedMonthsUseMidIntensity() {
        XCTAssertEqual(MonthBackgroundAsset.april.contrastProfile, .elevated)
        XCTAssertEqual(MonthBackgroundAsset.may.contrastProfile, .elevated)
        XCTAssertEqual(MonthBackgroundAsset.july.contrastProfile, .elevated)
        XCTAssertGreaterThan(
            MonthContrastProfile.elevated.baseScrimOpacity,
            MonthContrastProfile.standard.baseScrimOpacity
        )
    }

    func testStrongMonthsUseHeaviestTreatment() {
        let strong: [MonthBackgroundAsset] = [
            .january, .march, .june, .august, .october, .december
        ]
        for asset in strong {
            XCTAssertEqual(asset.contrastProfile, .strong, "\(asset)")
        }
        XCTAssertGreaterThan(
            MonthContrastProfile.strong.baseScrimOpacity,
            MonthContrastProfile.elevated.baseScrimOpacity
        )
        XCTAssertGreaterThanOrEqual(
            MonthContrastProfile.strong.topGradientOpacity,
            MonthContrastProfile.strong.midGradientOpacity
        )
    }

    func testCalendarAppearanceExposesActiveContrastProfile() {
        let appearance = CalendarAppearanceManager()
        appearance.prepareDisplayedMonth(3, year: 2026)
        XCTAssertEqual(appearance.activeMonthContrastProfile, .strong)
        appearance.prepareDisplayedMonth(2, year: 2026)
        XCTAssertEqual(appearance.activeMonthContrastProfile, .standard)
    }
}

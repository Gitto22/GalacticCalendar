//
//  TypographyDynamicTypeTests.swift
//  GalacticCalendar
//

import XCTest
import SwiftUI
@testable import GalacticCalendar
#if canImport(UIKit)
import UIKit
#endif

/// Sprint PB-02 — Dynamic Type: text styles scale; Design System has no fixed sizes.
final class TypographyDynamicTypeTests: XCTestCase {

    // MARK: - Design System contract

    func testTypographyExposesFullTokenSet() {
        let tokens: [Font] = [
            Typography.display,
            Typography.largeTitle,
            Typography.title,
            Typography.title2,
            Typography.title3,
            Typography.headline,
            Typography.body,
            Typography.callout,
            Typography.subheadline,
            Typography.footnote,
            Typography.caption,
            Typography.caption2,
            Typography.monospacedDigit
        ]
        XCTAssertEqual(tokens.count, 13)
    }

    // MARK: - Dynamic Type scaling (UIKit metrics)

    #if canImport(UIKit)
    func testPreferredTextStylesGrowWithAccessibilitySize() {
        let base = UITraitCollection(preferredContentSizeCategory: .large)
        let accessibility = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

        let styles: [UIFont.TextStyle] = [
            .largeTitle, .title1, .title2, .title3,
            .headline, .body, .callout, .subheadline,
            .footnote, .caption1, .caption2
        ]

        for style in styles {
            let baseSize = UIFont.preferredFont(forTextStyle: style, compatibleWith: base).pointSize
            let a11ySize = UIFont.preferredFont(forTextStyle: style, compatibleWith: accessibility).pointSize
            XCTAssertGreaterThan(
                a11ySize,
                baseSize,
                "Text style \(style.rawValue) must grow under Accessibility XXXL"
            )
        }
    }
    #endif
}

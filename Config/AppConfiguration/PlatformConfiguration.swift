//
//  PlatformConfiguration.swift
//  GalacticCalendar
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Supported Apple platforms for Galactic Calendar.
enum AppPlatform: String, Sendable, CaseIterable, Identifiable {

    // MARK: - Cases

    /// iPhone idiom.
    case iPhone

    /// iPad idiom.
    case iPad

    /// macOS idiom.
    case mac

    // MARK: - Identifiable

    /// Stable identifier for the platform.
    var id: String { rawValue }
}

/// Resolves the platform on which the application is running.
struct PlatformConfiguration: Sendable {

    // MARK: - Properties

    /// Detected platform for the current process.
    let platform: AppPlatform

    // MARK: - Lifecycle

    /// Creates a platform configuration using runtime detection.
    init(platform: AppPlatform = PlatformConfiguration.detect()) {
        self.platform = platform
    }

    // MARK: - Detection

    /// Detects the active platform for iPhone, iPad, and macOS.
    /// - Returns: Resolved ``AppPlatform``.
    static func detect() -> AppPlatform {
        #if os(macOS)
        return .mac
        #elseif canImport(UIKit)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return .iPad
        case .phone:
            return .iPhone
        default:
            return .iPhone
        }
        #else
        return .iPhone
        #endif
    }

    // MARK: - Convenience

    /// Indicates whether the current platform is macOS.
    var isMac: Bool {
        platform == .mac
    }

    /// Indicates whether the current platform is an iPad.
    var isPad: Bool {
        platform == .iPad
    }

    /// Indicates whether the current platform is an iPhone.
    var isPhone: Bool {
        platform == .iPhone
    }
}

//
//  BundleConfiguration.swift
//  GalacticCalendar
//

import Foundation

/// Reads bundle metadata that identifies the running product.
struct BundleConfiguration: Sendable {

    // MARK: - Properties

    /// Host bundle used for metadata lookup.
    private let bundle: Bundle

    // MARK: - Lifecycle

    /// Creates a bundle configuration.
    /// - Parameter bundle: Bundle to inspect. Defaults to the main bundle.
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    // MARK: - Identity

    /// Display name shown to users when available.
    var displayName: String {
        if let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           name.isEmpty == false {
            return name
        }

        if let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
           name.isEmpty == false {
            return name
        }

        return AppConstants.appName
    }

    /// Bundle identifier for the running target.
    var bundleIdentifier: String {
        bundle.bundleIdentifier ?? AppConstants.defaultBundleIdentifier
    }

    /// Marketing version string (`CFBundleShortVersionString`).
    var shortVersion: String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    /// Build number string (`CFBundleVersion`).
    var buildNumber: String {
        bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
}

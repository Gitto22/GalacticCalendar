//
//  SecretsPolicy.swift
//  GalacticCalendar
//

import Foundation

/// Documents the repository policy for secrets and credentials.
///
/// Sensitive values must be supplied through secure configuration
/// mechanisms outside source control — never committed to git.
enum SecretsPolicy {

    // MARK: - Guidance

    /// Reminder that secrets are never stored in the codebase.
    static let repositoryPolicy = "Do not commit API keys, tokens, or credentials."
}

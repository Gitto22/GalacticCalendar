//
//  SecretsPlaceholder.swift
//  GalacticCalendar
//

import Foundation

/// Marks the intentional absence of secrets inside the repository.
///
/// Sensitive values must be supplied through secure configuration
/// mechanisms outside source control.
enum SecretsPlaceholder {

    // MARK: - Guidance

    /// Reminder that secrets are never stored in the codebase.
    static let repositoryPolicy = "Do not commit API keys, tokens, or credentials."
}

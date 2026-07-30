//
//  UniverseMessageView.swift
//  GalacticCalendar
//

import SwiftUI

/// Native share control for a Universe Message.
///
/// Uses ``ShareLink`` only. Content must be prepared by
/// ``UniverseMessageViewModel`` (or History forwarding that API).
/// Not used by the approved Home card layout.
struct UniverseMessageView: View {

    // MARK: - Properties

    /// Pre-built share payload from the ViewModel layer.
    private let shareText: String

    // MARK: - Lifecycle

    /// Creates a share control.
    /// - Parameter shareText: Localized text to hand to the system share sheet.
    init(shareText: String) {
        self.shareText = shareText
    }

    // MARK: - Body

    var body: some View {
        ShareLink(item: shareText) {
            Image(systemName: Icons.Universe.share)
                .font(Typography.subheadline)
                .foregroundStyle(ColorPalette.onImageAccent.opacity(0.85))
                .frame(minWidth: Spacing.lg, minHeight: Spacing.lg)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "universe_share_a11y"))
        .accessibilityIdentifier("universe_share")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Universe Message Share") {
    ZStack {
        MonthBackgroundView()
        UniverseMessageView(
            shareText: UniverseMessageViewModel.makeShareText(
                message: "The best time to start is today.",
                date: Date()
            )
        )
    }
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}
#endif

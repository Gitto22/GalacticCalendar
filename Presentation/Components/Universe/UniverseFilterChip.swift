//
//  UniverseFilterChip.swift
//  GalacticCalendar
//

import SwiftUI

/// Reusable glass filter chip for Universe History (favorites / categories).
struct UniverseFilterChip: View {

    // MARK: - Properties

    /// Visible chip title.
    private let title: String

    /// Whether this chip is the active selection.
    private let isSelected: Bool

    /// Stable UI-test / VoiceOver identifier.
    private let accessibilityIdentifier: String

    /// Tap handler.
    private let action: () -> Void

    // MARK: - Lifecycle

    /// Creates a filter chip.
    /// - Parameters:
    ///   - title: Localized title.
    ///   - isSelected: Selection state.
    ///   - accessibilityIdentifier: Stable accessibility identifier.
    ///   - action: Tap handler.
    init(
        title: String,
        isSelected: Bool,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(
                    isSelected
                        ? ColorPalette.onImagePrimary
                        : ColorPalette.onImageAccent
                )
                .lineLimit(1)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .galacticGlassCard(
                    isSelected ? .regular : .subtle,
                    cornerRadius: Spacing.Radius.md
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(String(localized: "universe_filter_a11y_hint"))
        .accessibilityValue(
            isSelected
                ? String(localized: "calendar_day_selected_a11y")
                : String(localized: "calendar_day_not_selected_a11y")
        )
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Universe Filter Chip") {
    ZStack {
        MonthBackgroundView()
        HStack {
            UniverseFilterChip(
                title: "Todos",
                isSelected: true,
                accessibilityIdentifier: "universe_filter_preview_all",
                action: {}
            )
            UniverseFilterChip(
                title: "Favoritos",
                isSelected: false,
                accessibilityIdentifier: "universe_filter_preview_favorites",
                action: {}
            )
        }
        .padding()
    }
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}
#endif

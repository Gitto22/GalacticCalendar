//
//  UniverseMessageRow.swift
//  GalacticCalendar
//

import SwiftUI

/// Single history row for a Universe Message shown on a past day.
///
/// Displays date, full message, category, favorite toggle, and native share.
/// Optional ``onSelect`` opens detail from the content column without changing layout.
struct UniverseMessageRow: View {

    // MARK: - Properties

    /// Presentation row model.
    private let item: UniverseHistoryRowItem

    /// Pre-built share payload from ``UniverseHistoryViewModel``.
    private let shareText: String

    /// Called when the user taps the content area (detail).
    private let onSelect: (() -> Void)?

    /// Called when the user taps the favorite control.
    private let onToggleFavorite: () -> Void

    // MARK: - Lifecycle

    /// Creates a history row.
    /// - Parameters:
    ///   - item: Row content.
    ///   - shareText: Localized share payload.
    ///   - onSelect: Optional content tap (detail navigation).
    ///   - onToggleFavorite: Favorite button action.
    init(
        item: UniverseHistoryRowItem,
        shareText: String,
        onSelect: (() -> Void)? = nil,
        onToggleFavorite: @escaping () -> Void
    ) {
        self.item = item
        self.shareText = shareText
        self.onSelect = onSelect
        self.onToggleFavorite = onToggleFavorite
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            contentColumn
            trailingActions
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .galacticGlassCard(.subtle, cornerRadius: Spacing.Radius.lg)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Content

    /// Date, message, and category (tappable when ``onSelect`` is set).
    @ViewBuilder
    private var contentColumn: some View {
        if let onSelect {
            Button(action: onSelect) {
                contentLabels
            }
            .buttonStyle(.plain)
            .accessibilityLabel(contentAccessibilityLabel)
            .accessibilityHint(String(localized: "universe_history_row_a11y_hint"))
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("universe_history_row_\(item.messageId)")
        } else {
            contentLabels
                .accessibilityElement(children: .combine)
                .accessibilityLabel(contentAccessibilityLabel)
        }
    }

    /// Text stack for the leading column.
    private var contentLabels: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(item.dateText)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.universeAccent)

            Text(item.message)
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let categoryText = item.categoryText {
                Text(categoryText)
                    .font(Typography.caption2)
                    .foregroundStyle(ColorPalette.onImageAccent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// Combined VoiceOver label for the message content column.
    private var contentAccessibilityLabel: String {
        var parts = [item.dateText, item.message]
        if let categoryText = item.categoryText {
            parts.append(categoryText)
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Actions

    /// Favorite + share controls (History only; Home card unchanged).
    private var trailingActions: some View {
        VStack(spacing: Spacing.xs) {
            favoriteButton
            UniverseMessageView(shareText: shareText)
        }
    }

    /// Immediate favorite toggle (filled = favorito, outline = no favorito).
    private var favoriteButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: item.isFavorite ? Icons.Universe.favoriteFilled : Icons.Universe.favorite)
                .font(Typography.subheadline)
                .foregroundStyle(
                    item.isFavorite
                        ? ColorPalette.universeAccent
                        : ColorPalette.onImageAccent.opacity(ColorPalette.glassStrokeRegularOpacity)
                )
                .frame(minWidth: Spacing.lg, minHeight: Spacing.lg)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            item.isFavorite
                ? String(localized: "universe_history_favorite_a11y_on")
                : String(localized: "universe_history_favorite_a11y_off")
        )
        .accessibilityHint(String(localized: "universe_favorite_a11y_hint"))
        .accessibilityValue(
            item.isFavorite
                ? String(localized: "calendar_day_selected_a11y")
                : String(localized: "calendar_day_not_selected_a11y")
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("universe_history_favorite_\(item.messageId)")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Universe Message Row") {
    ZStack {
        MonthBackgroundView()
        UniverseMessageRow(
            item: UniverseHistoryRowItem(
                id: Date(),
                messageId: "um_001",
                dayStart: Date(),
                dateText: "29 Jul 2026",
                message: "The best time to start is today.",
                categoryText: "Motivation",
                category: .motivation,
                isFavorite: false
            ),
            shareText: UniverseMessageViewModel.makeShareText(
                message: "The best time to start is today.",
                date: Date()
            ),
            onToggleFavorite: {}
        )
        .padding(.horizontal, Spacing.pageHorizontal)
    }
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}
#endif

//
//  UniverseMessageCard.swift
//  GalacticCalendar
//

import SwiftUI

/// Approved Universe Message card for the Home screen.
///
/// Shows quote icon, title, sample message body, and decorative badge.
/// No database, favorites, sharing, or AI wiring.
struct UniverseMessageCard: View {

    // MARK: - Properties

    /// Sample message body used until a data source is connected.
    private let messageBody: String

    /// Card title localized as "Mensaje del Universo".
    private let title: String

    // MARK: - Lifecycle

    /// Creates a reusable Universe Message card.
    /// - Parameters:
    ///   - title: Localized card title.
    ///   - messageBody: Message text shown under the title.
    init(
        title: String = String(localized: "universe_message_caption"),
        messageBody: String = String(localized: "universe_message_body")
    ) {
        self.title = title
        self.messageBody = messageBody
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            messageColumn
            Spacer(minLength: Spacing.xs)
            decorativeBadge
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .galacticGlassCard(.subtle, cornerRadius: Spacing.Radius.lg)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Leading Content

    /// Quote icon, title, and sample message.
    private var messageColumn: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: Icons.Home.quote)
                .font(Typography.title)
                .foregroundStyle(ColorPalette.universeAccent)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(messageBody)
                    .font(Typography.callout)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(title)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.universeAccent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Trailing Decoration

    /// Decorative inspiration glyph on the trailing edge.
    private var decorativeBadge: some View {
        VStack(spacing: Spacing.xxs) {
            ZStack {
                Circle()
                    .stroke(GlassEffect.badgeGlowGradient, lineWidth: Spacing.headerControlStroke)
                    .frame(
                        width: LayoutConstants.inspirationBadgeSize,
                        height: LayoutConstants.inspirationBadgeSize
                    )

                Image(systemName: Icons.Home.inspiration)
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.onImagePrimary)
            }

            Text(String(localized: "universe_message_inspiration"))
                .font(Typography.caption2)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .lineLimit(1)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Universe Message Card") {
    ZStack {
        MonthBackgroundView()
        VStack(spacing: Spacing.sm) {
            HomeHeaderView()
            UniverseMessageCard()
                .padding(.horizontal, Spacing.pageHorizontal)
            Spacer()
        }
    }
    .environment(ThemeManager())
}
#endif

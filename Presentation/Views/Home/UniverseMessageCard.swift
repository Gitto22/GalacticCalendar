//
//  UniverseMessageCard.swift
//  GalacticCalendar
//

import SwiftUI

/// Approved Universe Message card for the Home screen.
///
/// Shows quote icon, message body from ``UniverseMessageViewModel``, caption,
/// and decorative badge. Layout, colors, and typography match the approved design.
/// Optional ``onTap`` opens detail without changing the visual layout.
struct UniverseMessageCard: View {

    // MARK: - Properties

    /// Presentation model providing today’s message body.
    private let viewModel: UniverseMessageViewModel

    /// Card title localized as "Mensaje del Universo".
    private let title: String

    /// Optional tap handler (opens detail). Visuals unchanged when `nil`.
    private let onTap: (() -> Void)?

    // MARK: - Lifecycle

    /// Creates a reusable Universe Message card.
    /// - Parameters:
    ///   - viewModel: Home Universe Message presentation model.
    ///   - title: Localized card title.
    ///   - onTap: Optional tap action (detail navigation).
    init(
        viewModel: UniverseMessageViewModel,
        title: String = String(localized: "universe_message_caption"),
        onTap: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.title = title
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(viewModel.message)
        .accessibilityHint(
            onTap == nil
                ? ""
                : String(localized: "universe_message_card_a11y_hint")
        )
        .accessibilityAddTraits(onTap == nil ? [] : .isButton)
        .accessibilityIdentifier("universe_message_card")
        .task {
            await viewModel.observeDayBoundary()
        }
    }

    // MARK: - Content

    /// Approved card layout (unchanged).
    private var cardContent: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            messageColumn
            Spacer(minLength: Spacing.xs)
            decorativeBadge
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .galacticGlassCard(.subtle, cornerRadius: Spacing.Radius.lg)
        .contentShape(Rectangle())
    }

    // MARK: - Leading Content

    /// Quote icon, message body, and caption.
    private var messageColumn: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: Icons.Home.quote)
                .font(Typography.title)
                .foregroundStyle(ColorPalette.universeAccent)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(viewModel.message)
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
    let engine = UniverseMessageEngine(repository: PreviewUniverseMessageRepository())
    let viewModel = UniverseMessageViewModel(engine: engine)

    ZStack {
        MonthBackgroundView()
        VStack(spacing: Spacing.sm) {
            HomeHeaderView()
            UniverseMessageCard(viewModel: viewModel)
                .padding(.horizontal, Spacing.pageHorizontal)
            Spacer()
        }
    }
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
    .task {
        await viewModel.loadInitial()
    }
}

@MainActor
private final class PreviewUniverseMessageRepository: UniverseMessageRepositoryProtocol {

    func fetchAll() async throws -> [UniverseMessage] {
        [
            UniverseMessage(
                id: "preview",
                textKey: "universe_message_body",
                category: .motivation
            )
        ]
    }

    func fetch(by id: String) async throws -> UniverseMessage? { nil }

    func ensureSeeded() async throws {}

    func fetchHistory() async throws -> [UniverseMessageHistoryEntry] { [] }

    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws {}

    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage {
        var copy = message
        copy.isFavorite.toggle()
        return copy
    }

    func favoriteMessages() async throws -> [UniverseMessage] { [] }

    func isFavorite(_ message: UniverseMessage) async throws -> Bool { message.isFavorite }
}
#endif

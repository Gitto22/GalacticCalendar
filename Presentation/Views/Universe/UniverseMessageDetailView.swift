//
//  UniverseMessageDetailView.swift
//  GalacticCalendar
//

import SwiftUI

/// Detail screen for a single Universe Message.
///
/// Shows full message, date, category, favorite state, and share.
/// Opened from Home or History via the existing full-screen cover pattern.
struct UniverseMessageDetailView: View {

    // MARK: - Properties

    /// Observable detail state and actions.
    @Bindable var viewModel: UniverseMessageDetailViewModel

    /// Dismiss handler for the close control.
    private let onDismiss: () -> Void

    // MARK: - Lifecycle

    /// Creates the detail screen.
    /// - Parameters:
    ///   - viewModel: Bound detail ViewModel.
    ///   - onDismiss: Called when the user closes the screen.
    init(viewModel: UniverseMessageDetailViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            MonthBackgroundView()

            VStack(spacing: Spacing.stackLoose) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        messageCard
                        actionsRow
                    }
                }
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.pageVertical)
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Header

    /// Title and close control.
    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Text(String(localized: "universe_detail_title"))
                .font(Typography.title2)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .lineLimit(1)
                .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)

            Spacer(minLength: Spacing.xs)

            GlassCircleButton(
                systemImage: Icons.Navigation.close,
                font: Typography.title3,
                foreground: ColorPalette.onImagePrimary,
                showsGlow: false
            ) {
                onDismiss()
            }
            .accessibilityLabel(String(localized: "event_editor_close"))
            .accessibilityHint(String(localized: "universe_close_a11y_hint"))
            .accessibilityIdentifier("universe_detail_close")
        }
    }

    // MARK: - Message

    /// Full message body with date and category metadata.
    private var messageCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(viewModel.dateText)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.universeAccent)

            Text(viewModel.message)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let categoryText = viewModel.categoryText {
                Text(categoryText)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.onImageAccent)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .galacticGlassCard(.subtle, cornerRadius: Spacing.Radius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "universe_detail_title"))
        .accessibilityValue(viewModel.message)
        .accessibilityIdentifier("universe_detail_message")
    }

    // MARK: - Actions

    /// Favorite toggle and share control.
    private var actionsRow: some View {
        HStack(spacing: Spacing.sm) {
            favoriteButton
            shareButton
            Spacer(minLength: 0)
        }
    }

    /// Favorite state control.
    private var favoriteButton: some View {
        Button {
            Task { await viewModel.toggleFavorite() }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(
                    systemName: viewModel.isFavorite
                        ? Icons.Universe.favoriteFilled
                        : Icons.Universe.favorite
                )
                .font(Typography.subheadline)

                Text(
                    viewModel.isFavorite
                        ? String(localized: "universe_history_favorite_a11y_on")
                        : String(localized: "universe_history_favorite_a11y_off")
                )
                .font(Typography.caption)
                .lineLimit(1)
            }
            .foregroundStyle(
                viewModel.isFavorite
                    ? ColorPalette.universeAccent
                    : ColorPalette.onImageAccent
            )
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .galacticGlassCard(.subtle, cornerRadius: Spacing.Radius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            viewModel.isFavorite
                ? String(localized: "universe_history_favorite_a11y_on")
                : String(localized: "universe_history_favorite_a11y_off")
        )
        .accessibilityHint(String(localized: "universe_favorite_a11y_hint"))
        .accessibilityValue(
            viewModel.isFavorite
                ? String(localized: "calendar_day_selected_a11y")
                : String(localized: "calendar_day_not_selected_a11y")
        )
        .accessibilityIdentifier("universe_detail_favorite")
    }

    /// Native share control.
    private var shareButton: some View {
        ShareLink(item: viewModel.shareText) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: Icons.Universe.share)
                    .font(Typography.subheadline)
                Text(String(localized: "universe_detail_share"))
                    .font(Typography.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(ColorPalette.onImageAccent)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .galacticGlassCard(.subtle, cornerRadius: Spacing.Radius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "universe_share_a11y"))
        .accessibilityIdentifier("universe_detail_share")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Universe Message Detail") {
    let repository = PreviewUniverseDetailRepository()
    let engine = UniverseMessageEngine(repository: repository)
    let service = UniverseMessageService(repository: repository, engine: engine)
    let viewModel = UniverseMessageDetailViewModel(
        context: UniverseMessageDetailContext(
            messageId: "um_001",
            dayStart: Date(),
            message: "The best time to start is today.",
            category: .motivation,
            isFavorite: false
        ),
        repository: repository,
        favoriteService: service
    )
    UniverseMessageDetailView(viewModel: viewModel, onDismiss: {})
        .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}

@MainActor
private final class PreviewUniverseDetailRepository: UniverseMessageRepositoryProtocol {

    private var isFavorite = false

    func fetchAll() async throws -> [UniverseMessage] {
        [
            UniverseMessage(
                id: "um_001",
                textKey: "universe_message_body",
                category: .motivation,
                isFavorite: isFavorite
            )
        ]
    }

    func fetch(by id: String) async throws -> UniverseMessage? {
        try await fetchAll().first { $0.id == id }
    }

    func ensureSeeded() async throws {}

    func fetchHistory() async throws -> [UniverseMessageHistoryEntry] { [] }

    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws {}

    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage {
        isFavorite.toggle()
        return UniverseMessage(
            id: message.id,
            textKey: "universe_message_body",
            category: .motivation,
            isFavorite: isFavorite
        )
    }

    func favoriteMessages() async throws -> [UniverseMessage] {
        try await fetchAll().filter(\.isFavorite)
    }

    func isFavorite(_ message: UniverseMessage) async throws -> Bool {
        isFavorite
    }
}
#endif

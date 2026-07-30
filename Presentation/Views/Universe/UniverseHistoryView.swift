//
//  UniverseHistoryView.swift
//  GalacticCalendar
//

import SwiftUI

/// History screen listing Universe Messages previously shown on Home.
///
/// Supports real-time search, Todos/Favoritos, horizontal category filter
/// (combinable with favorites), favorite toggles, and opening message detail.
/// Filter state is kept while this view (and its ViewModel) remain presented.
struct UniverseHistoryView: View {

    // MARK: - Properties

    /// Observable history state and search.
    @Bindable var viewModel: UniverseHistoryViewModel

    /// Dismiss handler for the close control.
    private let onDismiss: () -> Void

    // MARK: - Lifecycle

    /// Creates the history screen.
    /// - Parameters:
    ///   - viewModel: Bound history ViewModel.
    ///   - onDismiss: Called when the user closes the screen.
    init(viewModel: UniverseHistoryViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            MonthBackgroundView()

            VStack(spacing: Spacing.stackLoose) {
                header
                favoriteFilter
                categorySelector
                searchField
                content
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.pageVertical)
        }
        .task {
            await viewModel.load()
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingDetail,
            onDismiss: {
                viewModel.dismissDetail()
            }
        ) {
            if let detailViewModel = viewModel.detailViewModel {
                UniverseMessageDetailView(viewModel: detailViewModel) {
                    viewModel.dismissDetail()
                }
            }
        }
    }

    // MARK: - Header

    /// Title and close control.
    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Text(String(localized: "universe_history_title"))
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
            .accessibilityIdentifier("universe_history_close")
        }
    }

    // MARK: - Favorite Filter

    /// Todos / Favoritos scope control (instant filter).
    private var favoriteFilter: some View {
        HStack(spacing: Spacing.xs) {
            UniverseFilterChip(
                title: String(localized: "universe_history_filter_all"),
                isSelected: viewModel.favoriteFilter == .all,
                accessibilityIdentifier: "universe_history_filter_all"
            ) {
                viewModel.favoriteFilter = .all
            }

            UniverseFilterChip(
                title: String(localized: "universe_history_filter_favorites"),
                isSelected: viewModel.favoriteFilter == .favorites,
                accessibilityIdentifier: "universe_history_filter_favorites"
            ) {
                viewModel.favoriteFilter = .favorites
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Category Selector

    /// Horizontal category filter (combinable with favorites).
    private var categorySelector: some View {
        UniverseCategorySelector(
            categories: viewModel.selectableCategories,
            selectedCategory: viewModel.selectedCategory
        ) { category in
            viewModel.selectedCategory = category
        }
    }

    // MARK: - Search

    /// Real-time search field (message text + category).
    private var searchField: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: Icons.Universe.search)
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.onImageAccent)

            TextField(
                String(localized: "universe_history_search_placeholder"),
                text: $viewModel.searchText
            )
            .font(Typography.callout)
            .foregroundStyle(ColorPalette.onImagePrimary)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .autocorrectionDisabled()
            .accessibilityLabel(String(localized: "universe_history_search_placeholder"))
            .accessibilityIdentifier("universe_history_search")
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .galacticGlassCard(.subtle, cornerRadius: Spacing.Radius.lg)
    }

    // MARK: - Content

    /// List, empty history, or empty filter / search results.
    @ViewBuilder
    private var content: some View {
        if viewModel.isHistoryEmpty {
            emptyHistory
        } else if viewModel.isFilterEmpty {
            emptyFilter
        } else {
            historyList
        }
    }

    /// Scrollable history rows (newest first).
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.displayedRows) { item in
                    UniverseMessageRow(
                        item: item,
                        shareText: viewModel.shareText(for: item),
                        onSelect: {
                            viewModel.presentDetail(for: item)
                        }
                    ) {
                        Task { await viewModel.toggleFavorite(for: item) }
                    }
                }
            }
        }
    }

    /// Friendly empty state when no messages have been shown yet.
    private var emptyHistory: some View {
        VStack(spacing: Spacing.sm) {
            Spacer(minLength: Spacing.xl)
            Image(systemName: Icons.Home.universeMessage)
                .font(Typography.title)
                .foregroundStyle(ColorPalette.universeAccent)
            Text(String(localized: "universe_history_empty_title"))
                .font(Typography.title3)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .multilineTextAlignment(.center)
            Text(String(localized: "universe_history_empty_message"))
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.onImageAccent)
                .multilineTextAlignment(.center)
            Spacer(minLength: Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
    }

    /// Empty state when filters / search match nothing.
    private var emptyFilter: some View {
        VStack(spacing: Spacing.sm) {
            Spacer(minLength: Spacing.xl)
            Text(
                viewModel.favoriteFilter == .favorites
                    ? String(localized: "universe_history_favorites_empty")
                    : String(localized: "universe_history_search_empty")
            )
            .font(Typography.callout)
            .foregroundStyle(ColorPalette.onImageAccent)
            .multilineTextAlignment(.center)
            Spacer(minLength: Spacing.xl)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Universe History") {
    let repository = PreviewUniverseHistoryRepository()
    let engine = UniverseMessageEngine(repository: repository)
    let service = UniverseMessageService(repository: repository, engine: engine)
    let viewModel = UniverseHistoryViewModel(
        repository: repository,
        favoriteService: service
    )
    UniverseHistoryView(viewModel: viewModel, onDismiss: {})
        .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}

@MainActor
private final class PreviewUniverseHistoryRepository: UniverseMessageRepositoryProtocol {

    private var favoriteIDs: Set<String> = []

    func fetchAll() async throws -> [UniverseMessage] {
        [
            UniverseMessage(
                id: "um_001",
                textKey: "universe_message_body",
                category: .motivation,
                isFavorite: favoriteIDs.contains("um_001")
            )
        ]
    }

    func fetch(by id: String) async throws -> UniverseMessage? {
        try await fetchAll().first { $0.id == id }
    }

    func ensureSeeded() async throws {}

    func fetchHistory() async throws -> [UniverseMessageHistoryEntry] {
        [
            UniverseMessageHistoryEntry(
                dayStart: Date(),
                messageId: "um_001",
                textKey: "universe_message_body",
                category: .motivation,
                isFavorite: favoriteIDs.contains("um_001")
            )
        ]
    }

    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws {}

    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage {
        if favoriteIDs.contains(message.id) {
            favoriteIDs.remove(message.id)
        } else {
            favoriteIDs.insert(message.id)
        }
        return UniverseMessage(
            id: message.id,
            textKey: message.textKey.isEmpty ? "universe_message_body" : message.textKey,
            category: message.category,
            isFavorite: favoriteIDs.contains(message.id)
        )
    }

    func favoriteMessages() async throws -> [UniverseMessage] {
        try await fetchAll().filter(\.isFavorite)
    }

    func isFavorite(_ message: UniverseMessage) async throws -> Bool {
        favoriteIDs.contains(message.id)
    }
}
#endif

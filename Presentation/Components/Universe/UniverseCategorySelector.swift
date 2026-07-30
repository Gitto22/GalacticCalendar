//
//  UniverseCategorySelector.swift
//  GalacticCalendar
//

import SwiftUI

/// Horizontal category selector for Universe History.
///
/// `selectedCategory == nil` means “all categories”.
struct UniverseCategorySelector: View {

    // MARK: - Properties

    /// Ordered selectable categories.
    private let categories: [UniverseCategory]

    /// Currently selected category (`nil` = all).
    private let selectedCategory: UniverseCategory?

    /// Called when the user picks “all” or a specific category.
    private let onSelect: (UniverseCategory?) -> Void

    // MARK: - Lifecycle

    /// Creates a horizontal category selector.
    /// - Parameters:
    ///   - categories: Categories to display after “All”.
    ///   - selectedCategory: Active selection.
    ///   - onSelect: Selection callback.
    init(
        categories: [UniverseCategory],
        selectedCategory: UniverseCategory?,
        onSelect: @escaping (UniverseCategory?) -> Void
    ) {
        self.categories = categories
        self.selectedCategory = selectedCategory
        self.onSelect = onSelect
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                UniverseFilterChip(
                    title: String(localized: "universe_history_category_all"),
                    isSelected: selectedCategory == nil,
                    accessibilityIdentifier: "universe_category_all"
                ) {
                    onSelect(nil)
                }

                ForEach(categories) { category in
                    UniverseFilterChip(
                        title: UniverseCategoryDisplayNames.displayName(for: category),
                        isSelected: selectedCategory == category,
                        accessibilityIdentifier: "universe_category_\(category.rawValue)"
                    ) {
                        onSelect(category)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Universe Category Selector") {
    ZStack {
        MonthBackgroundView()
        UniverseCategorySelector(
            categories: UniverseCategory.selectableCases,
            selectedCategory: .motivation,
            onSelect: { _ in }
        )
        .padding(.horizontal, Spacing.pageHorizontal)
    }
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}
#endif

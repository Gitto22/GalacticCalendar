//
//  EventColorTitleRow.swift
//  GalacticCalendar
//

import SwiftUI

/// Shared color-dot + title (+ optional subtitle / trailing) used by Search and Agenda.
///
/// Pure layout chrome — callers own buttons, cards, and navigation.
struct EventColorTitleRow: View {

    // MARK: - Properties

    private let color: EventColor
    private let title: String
    private let titleFont: Font
    private let titleLineLimit: Int
    private let subtitle: String?
    private let trailing: String?

    // MARK: - Lifecycle

    init(
        color: EventColor,
        title: String,
        titleFont: Font = Typography.headline,
        titleLineLimit: Int = 1,
        subtitle: String? = nil,
        trailing: String? = nil
    ) {
        self.color = color
        self.title = title
        self.titleFont = titleFont
        self.titleLineLimit = titleLineLimit
        self.subtitle = subtitle
        self.trailing = trailing
    }

    init(
        event: Event,
        titleFont: Font = Typography.headline,
        titleLineLimit: Int = 1,
        subtitle: String? = nil,
        trailing: String? = nil
    ) {
        self.init(
            color: event.color,
            title: event.title,
            titleFont: titleFont,
            titleLineLimit: titleLineLimit,
            subtitle: subtitle,
            trailing: trailing
        )
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(ColorPalette.color(for: color))
                .frame(
                    width: LayoutConstants.eventColorDotSize,
                    height: LayoutConstants.eventColorDotSize
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .lineLimit(titleLineLimit)
                    .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.footnote)
                        .foregroundStyle(ColorPalette.editorPlaceholder)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if let trailing {
                Text(trailing)
                    .font(Typography.caption2)
                    .foregroundStyle(ColorPalette.editorPlaceholder)
                    .lineLimit(1)
            }
        }
    }
}

//
//  EventTemplatePickerView.swift
//  GalacticCalendar
//

import SwiftUI

/// Picker that applies an ``EventTemplate`` when creating a new event.
struct EventTemplatePickerView: View {

    @Bindable var viewModel: EventTemplatePickerViewModel
    private let onSelect: (EventTemplate) -> Void
    private let onDismiss: () -> Void

    @State private var isShowingErrorAlert: Bool = false

    init(
        viewModel: EventTemplatePickerViewModel,
        onSelect: @escaping (EventTemplate) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            MonthBackgroundView()

            VStack(spacing: Spacing.stackLoose) {
                header
                content
                manageButton
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.pageVertical)
        }
        .task {
            await viewModel.bootstrap()
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingManager,
            onDismiss: { viewModel.dismissManager() }
        ) {
            if let manager = viewModel.templatesViewModel {
                EventTemplatesView(viewModel: manager) {
                    viewModel.dismissManager()
                }
            }
        }
        .onChange(of: viewModel.lastError) { _, error in
            isShowingErrorAlert = error != nil
        }
        .alert(
            String(localized: "event_error_alert_title"),
            isPresented: $isShowingErrorAlert
        ) {
            Button(String(localized: "event_error_alert_dismiss"), role: .cancel) {
                viewModel.clearLastError()
            }
        } message: {
            Text(viewModel.errorAlertMessage ?? String(localized: "event_error_unknown"))
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Text(String(localized: "event_template_picker_title"))
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
            .accessibilityLabel(Text(String(localized: "event_templates_close")))
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.templates.isEmpty {
            Text(String(localized: "event_templates_empty"))
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.editorPlaceholder)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        } else {
            List {
                ForEach(viewModel.templates) { template in
                    Button {
                        onSelect(template)
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Circle()
                                .fill(ColorPalette.color(for: template.color))
                                .frame(
                                    width: LayoutConstants.eventColorDotSize,
                                    height: LayoutConstants.eventColorDotSize
                                )

                            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                                Text(template.name)
                                    .font(Typography.headline)
                                    .foregroundStyle(ColorPalette.onImagePrimary)
                                    .lineLimit(1)

                                Text(template.title)
                                    .font(Typography.footnote)
                                    .foregroundStyle(ColorPalette.editorPlaceholder)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: Spacing.xs)
                        }
                        .padding(.vertical, Spacing.xxs)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(
                        EdgeInsets(
                            top: Spacing.xxs,
                            leading: Spacing.sm,
                            bottom: Spacing.xxs,
                            trailing: Spacing.sm
                        )
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.subtle, cornerRadius: Spacing.Radius.xl)
        }
    }

    private var manageButton: some View {
        Button {
            viewModel.presentManager()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: Icons.Events.template)
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.editorAccent)

                Text(String(localized: "event_templates_manage"))
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.onImagePrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Spacing.Radius.lg, style: .continuous)
                    .fill(ColorPalette.editorTileFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Spacing.Radius.lg, style: .continuous)
                    .stroke(GlassEffect.linearGlowGradient, lineWidth: Spacing.cardStroke)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(localized: "event_templates_manage")))
    }
}

//
//  EventTemplatesView.swift
//  GalacticCalendar
//

import SwiftUI

/// Offline event-template management list (create / edit / duplicate / delete).
struct EventTemplatesView: View {

    @Bindable var viewModel: EventTemplatesViewModel
    private let onDismiss: () -> Void

    @State private var isShowingErrorAlert: Bool = false
    @State private var templatePendingDeletion: EventTemplate?

    init(viewModel: EventTemplatesViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            MonthBackgroundView()

            VStack(spacing: Spacing.stackLoose) {
                header
                content
                createButton
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.pageVertical)
        }
        .task {
            await viewModel.bootstrap()
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingEditor,
            onDismiss: { viewModel.dismissEditor() }
        ) {
            if let editor = viewModel.editorViewModel {
                ZStack {
                    MonthBackgroundView()
                    EventTemplateEditorView(viewModel: editor) {
                        viewModel.dismissEditor()
                    }
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
        .confirmationDialog(
            String(localized: "event_template_delete_confirm_title"),
            isPresented: Binding(
                get: { templatePendingDeletion != nil },
                set: { if $0 == false { templatePendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "event_template_delete_confirm_action"), role: .destructive) {
                if let template = templatePendingDeletion {
                    Task { await viewModel.delete(template) }
                }
                templatePendingDeletion = nil
            }
            Button(String(localized: "event_delete_cancel"), role: .cancel) {
                templatePendingDeletion = nil
            }
        } message: {
            Text(String(localized: "event_template_delete_confirm_message"))
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Text(String(localized: "event_templates_title"))
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
                    templateRow(template)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.subtle, cornerRadius: Spacing.Radius.xl)
        }
    }

    private func templateRow(_ template: EventTemplate) -> some View {
        Button {
            viewModel.presentEdit(template)
        } label: {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(ColorPalette.color(for: template.color))
                    .frame(width: LayoutConstants.eventColorDotSize, height: LayoutConstants.eventColorDotSize)

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

                Image(systemName: Icons.Events.selectorChevron)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.onImageAccent)
            }
            .padding(.vertical, Spacing.xxs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowInsets(
            EdgeInsets(top: Spacing.xxs, leading: Spacing.sm, bottom: Spacing.xxs, trailing: Spacing.sm)
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .contextMenu {
            Button {
                viewModel.presentEdit(template)
            } label: {
                Label(String(localized: "day_events_action_edit"), systemImage: Icons.Events.edit)
            }
            Button {
                Task { await viewModel.duplicate(template) }
            } label: {
                Label(String(localized: "event_template_action_duplicate"), systemImage: Icons.Events.duplicate)
            }
            Button(role: .destructive) {
                templatePendingDeletion = template
            } label: {
                Label(String(localized: "day_events_action_delete"), systemImage: Icons.Events.delete)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                templatePendingDeletion = template
            } label: {
                Label(String(localized: "day_events_action_delete"), systemImage: Icons.Events.delete)
            }
        }
    }

    private var createButton: some View {
        Button {
            viewModel.presentCreate()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: Icons.Events.add)
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.editorAccent)

                Text(String(localized: "event_templates_new"))
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
            .appShadow(Shadows.glowCard)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(localized: "event_templates_new")))
    }
}

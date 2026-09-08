//
//  TemplateListView.swift
//  Nippardation
//
//  Workout library — every workout the user has built, one 66pt row each.
//  Pushed from Plan → ··· → Workout library. System nav bar, inline title, back button.
//

import SwiftUI

struct TemplateListView: View {

    @StateObject private var viewModel = TemplateListViewModel()
    @StateObject private var shareViewModel = ShareViewModel()

    @State private var showCreateTemplate = false
    @State private var templateToDelete: Template?
    @State private var showDeleteConfirmation = false
    @State private var sharingTemplate: Template?
    @State private var showShareSheet = false

    var body: some View {
        content
            .navigationTitle("Workout library")
            .navigationBarTitleDisplayMode(.inline)
            .voidScreen()
            .sheet(isPresented: $showCreateTemplate) {
                NavigationStack {
                    TemplateEditorView(onSave: { template in
                        viewModel.handleTemplateSaved(template)
                        showCreateTemplate = false
                    })
                }
            }
            .alert("Delete workout", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    templateToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let template = templateToDelete {
                        viewModel.deleteTemplate(template)
                    }
                    templateToDelete = nil
                }
            } message: {
                Text("This removes the workout from your library. It cannot be undone.")
            }
            .sheet(isPresented: $showShareSheet, onDismiss: { sharingTemplate = nil }) {
                if let url = shareViewModel.shareURL, let template = sharingTemplate {
                    ShareActivityView(activityItems: [
                        PlanShareItemSource(
                            url: url,
                            title: template.name,
                            subtitle: PlanShareItemSource.subtitle(for: template)
                        )
                    ])
                }
            }
            .onChange(of: shareViewModel.shareURL) { _, url in
                if url != nil {
                    showShareSheet = true
                }
            }
            .alert("Sharing error", isPresented: .init(
                get: { shareViewModel.error != nil },
                set: { if !$0 { shareViewModel.clearError() } }
            )) {
                Button("OK") { shareViewModel.clearError() }
            } message: {
                Text(shareViewModel.error ?? "")
            }
            .onAppear {
                if viewModel.templates.isEmpty {
                    viewModel.loadTemplates()
                } else {
                    viewModel.loadIfStale()
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error ?? "An unknown error occurred")
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.templates.isEmpty {
            loadingView
        } else {
            library
        }
    }

    private var loadingView: some View {
        VStack(spacing: VoidSpace.s3) {
            ProgressView()
                .tint(VoidColor.text2)
            Text("Loading")
                .voidEyebrowSm()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var library: some View {
        ScrollView {
            VStack(spacing: VoidSpace.s3) {
                VoidTextField(placeholder: "Search workouts", text: $viewModel.searchText, icon: .search)
                    .padding(.horizontal, VoidSpace.insetCard)
                    .padding(.top, VoidSpace.s2)

                VoidListPanel {
                    NewWorkoutRow {
                        showCreateTemplate = true
                    }

                    if viewModel.templates.isEmpty {
                        VoidHairline()
                        VoidPlaceholder(eyebrow: "No workouts yet", caption: "Build one here, or let a plan add them.")
                    } else if viewModel.filteredTemplates.isEmpty {
                        VoidHairline()
                        VoidPlaceholder(eyebrow: "No matches")
                    } else {
                        ForEach(viewModel.filteredTemplates) { template in
                            VoidHairline()
                            workoutRow(template)
                        }
                    }
                }
                .padding(.bottom, VoidSpace.s6)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            await viewModel.refreshAsync()
        }
    }

    private func workoutRow(_ template: Template) -> some View {
        NavigationLink {
            TemplateEditorView(
                existingTemplate: template,
                onSave: { saved in
                    viewModel.handleTemplateSaved(saved)
                }
            )
        } label: {
            WorkoutLibraryRow(template: template)
        }
        .buttonStyle(VoidRowButtonStyle())
        .contextMenu {
            Button {
                viewModel.duplicateTemplate(template)
            } label: {
                Label("Duplicate", systemImage: GapIcon.duplicate)
            }

            Button {
                share(template)
            } label: {
                Label("Share", systemImage: VoidIcon.share.systemName)
            }

            Divider()

            Button(role: .destructive) {
                templateToDelete = template
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: VoidIcon.trash.systemName)
            }
        }
    }

    private func share(_ template: Template) {
        // ShareViewModel.createShare drops the call while a link is in flight; keep the
        // template in step with it so the preview card never names a different workout.
        guard !shareViewModel.isLoading else { return }
        sharingTemplate = template
        shareViewModel.createShare(type: "template", itemId: template.serverId)
    }
}

// MARK: - Rows

/// 66pt library row: 52pt workout tile · name · "6 exercises · ~55 min · edited 2d ago" · chevron.
private struct WorkoutLibraryRow: View {
    let template: Template

    var body: some View {
        HStack(spacing: VoidSpace.s3) {
            WorkoutTile(glyph: VoidIcon.workoutGlyph(for: template.name), raised: true)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(VoidFont.bodyStrong)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(1)
                Text(caption)
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.text2)
                    .lineLimit(1)
            }

            Spacer(minLength: VoidSpace.s2)

            VoidChevron()
        }
        .frame(height: VoidSize.listRow)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var caption: String {
        [PlanShareItemSource.subtitle(for: template), Self.edited(template.updatedAt)]
            .joined(separator: VoidFormat.dot)
    }

    /// "edited today" · "edited 2d ago" · "edited 3w ago" · "edited 2mo ago" · "edited 1y ago"
    static func edited(_ date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: now)
        ).day ?? 0

        switch days {
        case ..<1: return "edited today"
        case 1..<7: return "edited \(days)d ago"
        case 7..<30: return "edited \(days / 7)w ago"
        case 30..<365: return "edited \(days / 30)mo ago"
        default: return "edited \(days / 365)y ago"
        }
    }
}

/// First row of the library: a plus tile and "New workout".
private struct NewWorkoutRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: VoidSpace.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous)
                        .fill(VoidColor.panel2)
                    Image(systemName: VoidIcon.plus.systemName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(VoidColor.text)
                }
                .frame(width: VoidSize.tile, height: VoidSize.tile)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("New workout")
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                    Text("Pick exercises, sets and rest")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                }

                Spacer(minLength: VoidSpace.s2)

                VoidChevron()
            }
            .frame(height: VoidSize.listRow)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidRowButtonStyle())
        .accessibilityLabel("New workout")
    }
}

/// SF Symbols the Void glyph set does not name yet.
private enum GapIcon {
    static let duplicate = "doc.on.doc"
}

// MARK: - Previews

#Preview {
    NavigationStack {
        TemplateListView()
    }
    .withDependencies(.preview)
}

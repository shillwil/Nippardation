//
//  TemplateListView.swift
//  Nippardation
//
//  Workout library — every workout the user has built, one row each, in an inset-grouped
//  List with the system search field. Pushed from Plan → ··· → Workout library. New workout
//  is the toolbar's add button; swipe a row to duplicate or delete it (long-press also shares).
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
        library
            .navigationTitle("Workout library")
            .navigationBarTitleDisplayMode(.inline)
            .voidScreen()
            .searchable(text: $viewModel.searchText, prompt: "Search workouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New workout", systemImage: VoidIcon.plus.systemName) {
                        showCreateTemplate = true
                    }
                }
            }
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
                    .presentationDetents([.medium, .large])
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

    /// The List is always there, so pull-to-refresh and search work even when it's empty;
    /// loading and empty states sit over it.
    private var library: some View {
        List {
            ForEach(viewModel.filteredTemplates) { template in
                workoutRow(template)
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            emptyState
        }
        .refreshable {
            await viewModel.refreshAsync()
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.templates.isEmpty {
            if viewModel.isLoading {
                ProgressView {
                    Text("Loading")
                        .voidEyebrowSm()
                }
                .tint(VoidColor.text2)
            } else {
                ContentUnavailableView {
                    Label("No workouts yet", systemImage: VoidIcon.library.systemName)
                } description: {
                    Text("Build one, or let a plan add them.")
                } actions: {
                    Button {
                        showCreateTemplate = true
                    } label: {
                        Text("New workout")
                            .foregroundStyle(VoidColor.onPlasma)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(VoidColor.plasma)
                }
            }
        } else if viewModel.filteredTemplates.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
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
        .listRowBackground(VoidColor.panel)
        .listRowSeparatorTint(VoidColor.hairline)
        .swipeActions(edge: .trailing) {
            // No destructive role: Delete asks first, and the role would animate the row
            // away before the answer.
            Button {
                requestDelete(template)
            } label: {
                Label("Delete", systemImage: VoidIcon.trash.systemName)
            }
            .tint(.red)

            Button {
                viewModel.duplicateTemplate(template)
            } label: {
                Label("Duplicate", systemImage: GapIcon.duplicate)
            }
            .tint(.gray)
        }
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
                requestDelete(template)
            } label: {
                Label("Delete", systemImage: VoidIcon.trash.systemName)
            }
        }
    }

    private func requestDelete(_ template: Template) {
        templateToDelete = template
        showDeleteConfirmation = true
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

/// Library row: 52pt workout tile · name · "6 exercises · ~55 min · edited 2d ago".
/// The NavigationLink around it draws the disclosure chevron.
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
        }
        .padding(.vertical, VoidSpace.s1)
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

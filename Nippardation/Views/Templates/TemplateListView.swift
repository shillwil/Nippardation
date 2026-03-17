//
//  TemplateListView.swift
//  Nippardation
//
//  Grid view for displaying and managing workout templates
//

import SwiftUI

struct TemplateListView: View {

    @StateObject private var viewModel = TemplateListViewModel()
    @State private var showCreateTemplate = false
    @State private var templateToDelete: Template?
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @StateObject private var shareViewModel = ShareViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm)
    ]

    var body: some View {
        content
            .navigationTitle("My Templates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateTemplate) {
                NavigationStack {
                    TemplateEditorView()
                }
            }
            .onChange(of: showCreateTemplate) { oldValue, newValue in
                // Refresh list after create sheet closes so newly created templates appear immediately.
                if oldValue && !newValue {
                    viewModel.loadTemplates(refresh: true)
                }
            }
            .alert("Delete Template", isPresented: $showDeleteConfirmation) {
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
                Text("Are you sure you want to delete this template? This cannot be undone.")
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareViewModel.shareURL {
                    ShareActivityView(activityItems: [url])
                }
            }
            .onChange(of: shareViewModel.shareURL) { _, url in
                if url != nil {
                    showShareSheet = true
                }
            }
            .alert("Sharing Error", isPresented: .init(
                get: { shareViewModel.error != nil },
                set: { if !$0 { shareViewModel.clearError() } }
            )) {
                Button("OK") { shareViewModel.clearError() }
            } message: {
                Text(shareViewModel.error ?? "")
            }
            .refreshable {
                await viewModel.refreshAsync()
            }
            .onAppear {
                if viewModel.templates.isEmpty {
                    viewModel.loadTemplates()
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

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.templates.isEmpty {
            loadingView
        } else if viewModel.templates.isEmpty {
            TemplateEmptyStateView(onCreate: { showCreateTemplate = true })
        } else {
            templateGrid
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
            Text("Loading templates...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var templateGrid: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // Search bar
                searchBar

                // Grid
                LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                    // "New Template" card as first item
                    NewTemplateCard(onTap: { showCreateTemplate = true })

                    ForEach(viewModel.filteredTemplates) { template in
                        NavigationLink(destination: TemplateEditorView(existingTemplate: template)) {
                            TemplateGridCard(template: template)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                viewModel.duplicateTemplate(template)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }

                            Button {
                                shareViewModel.createShare(type: "template", itemId: template.serverId)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            Button(role: .destructive) {
                                templateToDelete = template
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private var searchBar: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search templates...", text: $viewModel.searchText)
                .textFieldStyle(.plain)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        TemplateListView()
    }
    .withDependencies(.preview)
}

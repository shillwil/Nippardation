//
//  TemplateListView.swift
//  Nippardation
//
//  List view for displaying and managing workout templates
//

import SwiftUI

struct TemplateListView: View {

    @StateObject private var viewModel = TemplateListViewModel()
    @State private var showCreateTemplate = false
    @State private var templateToDelete: Template?
    @State private var showDeleteConfirmation = false

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
            .refreshable {
                await viewModel.refreshAsync()
            }
            .onAppear {
                if viewModel.templates.isEmpty {
                    viewModel.loadTemplates()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.templates.isEmpty {
            loadingView
        } else if viewModel.templates.isEmpty {
            emptyView
        } else {
            templateList
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading templates...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Templates", systemImage: "doc.text")
        } description: {
            Text("Create your first template to get started")
        } actions: {
            Button("Create Template") {
                showCreateTemplate = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var templateList: some View {
        List {
            ForEach(viewModel.templates) { template in
                NavigationLink(destination: TemplateEditorView(existingTemplate: template)) {
                    TemplateCard(template: template)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        templateToDelete = template
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        viewModel.duplicateTemplate(template)
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Template Card

struct TemplateCard: View {

    let template: Template

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)

                Spacer()

                if template.isAiGenerated {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.caption)
                }
            }

            if let description = template.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label("\(template.exerciseCount) exercises", systemImage: "figure.strengthtraining.traditional")
                Label("\(template.totalWorkingSets) sets", systemImage: "number")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        TemplateListView()
    }
    .withDependencies(.preview)
}

//
//  ProgramListView.swift
//  Nippardation
//
//  Card-based view for displaying and managing workout programs
//

import SwiftUI

struct ProgramListView: View {

    @StateObject private var viewModel = ProgramListViewModel()
    @State private var showCreateProgram = false
    @State private var showAIWizard = false
    @State private var showShareSheet = false
    @StateObject private var shareViewModel = ShareViewModel()

    var body: some View {
        content
            .navigationTitle("My Programs")
            .sheet(isPresented: $showCreateProgram) {
                NavigationStack {
                    ProgramWizardView()
                }
            }
            .fullScreenCover(isPresented: $showAIWizard) {
                AIWizardView()
            }
            .onChange(of: showCreateProgram) { oldValue, newValue in
                if oldValue && !newValue {
                    viewModel.loadPrograms(refresh: true)
                }
            }
            .onChange(of: showAIWizard) { oldValue, newValue in
                if oldValue && !newValue {
                    viewModel.loadPrograms(refresh: true)
                }
            }
            .alert("Delete Program", isPresented: $viewModel.showSimpleDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    viewModel.clearDeleteState()
                }
                Button("Delete", role: .destructive) {
                    if let program = viewModel.programToDelete {
                        viewModel.deleteProgram(program)
                    }
                    viewModel.clearDeleteState()
                }
            } message: {
                Text("Are you sure you want to delete this program? This cannot be undone.")
            }
            .sheet(isPresented: $viewModel.showTemplateDeleteSheet) {
                if let detail = viewModel.programToDeleteDetail {
                    ProgramDeleteConfirmationView(
                        program: detail,
                        isDeletingProgram: viewModel.isDeletingProgram,
                        onConfirmDelete: { keepIds in
                            viewModel.deleteProgramWithTemplates(keepTemplateIds: keepIds)
                            // Sheet dismisses when ViewModel sets showTemplateDeleteSheet = false
                            // AFTER the deletion (including cache cleanup) completes.
                        },
                        onCancel: {
                            viewModel.clearDeleteState()
                        }
                    )
                }
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
                if viewModel.programs.isEmpty {
                    viewModel.loadPrograms()
                }
            }
            .overlay {
                if viewModel.isFetchingDeleteDetail {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView()
                                .padding()
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppCornerRadius.medium))
                        }
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
        if viewModel.isLoading && viewModel.programs.isEmpty {
            loadingView
        } else if viewModel.programs.isEmpty {
            ProgramEmptyStateView(
                onCreate: { showCreateProgram = true },
                onGenerateWithAI: { showAIWizard = true }
            )
        } else {
            programList
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
            Text("Loading programs...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var programList: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: AppSpacing.md) {
                    ForEach(viewModel.programs) { program in
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            NavigationLink(destination: ProgramDetailView(programServerId: program.serverId)) {
                                ProgramLibraryCard(program: program)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if !program.isActive {
                                    Button {
                                        viewModel.activateProgram(program)
                                    } label: {
                                        Label("Activate", systemImage: "checkmark.circle")
                                    }
                                }

                                Button {
                                    viewModel.duplicateProgram(program)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }

                                Button {
                                    shareViewModel.createShare(type: "program", itemId: program.serverId)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    viewModel.prepareDeleteProgram(program)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }

                            if program.isActive {
                                Label("Current Active Program", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, AppSpacing.xs)
                            } else {
                                Button {
                                    viewModel.activateProgram(program)
                                } label: {
                                    Label("Set As Active", systemImage: "checkmark.circle")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                    }

                    if viewModel.hasMore {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, AppSpacing.md)
                        .onAppear {
                            viewModel.loadMore()
                        }
                    }
                }
                .padding(AppSpacing.md)
                // Extra bottom padding so content isn't hidden behind the pinned buttons
                .padding(.bottom, 100)
            }

            pinnedBottomButtons
        }
    }

    private var pinnedBottomButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            AIGradientButton("Generate with AI") {
                showAIWizard = true
            }

            Button {
                showCreateProgram = true
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Manually")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.lg)
        .background(
            .ultraThinMaterial,
            in: Rectangle()
        )
        .mask(
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 16)

                Color.black
            }
        )
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ProgramListView()
    }
    .withDependencies(.preview)
}

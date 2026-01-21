//
//  ProgramListView.swift
//  Nippardation
//
//  List view for displaying and managing workout programs
//

import SwiftUI

struct ProgramListView: View {

    @StateObject private var viewModel = ProgramListViewModel()
    @State private var showCreateProgram = false
    @State private var programToDelete: Program?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.programs.isEmpty {
                loadingView
            } else if viewModel.programs.isEmpty {
                emptyView
            } else {
                programList
            }
        }
        .navigationTitle("My Programs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateProgram = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateProgram) {
            NavigationStack {
                ProgramEditorView()
            }
        }
        .alert("Delete Program", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                programToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let program = programToDelete {
                    viewModel.deleteProgram(program)
                }
                programToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this program? This cannot be undone.")
        }
        .refreshable {
            viewModel.loadPrograms(refresh: true)
        }
        .onAppear {
            if viewModel.programs.isEmpty {
                viewModel.loadPrograms()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading programs...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Programs", systemImage: "list.bullet.clipboard")
        } description: {
            Text("Create your first program to get started")
        } actions: {
            Button("Create Program") {
                showCreateProgram = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var programList: some View {
        List {
            ForEach(viewModel.programs) { program in
                NavigationLink(destination: ProgramDetailView(programServerId: program.serverId)) {
                    ProgramCard(program: program)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        programToDelete = program
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    if !program.isActive {
                        Button {
                            viewModel.activateProgram(program)
                        } label: {
                            Label("Activate", systemImage: "checkmark.circle")
                        }
                        .tint(.green)
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        viewModel.duplicateProgram(program)
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    .tint(.blue)
                }
            }

            if viewModel.hasMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .onAppear {
                    viewModel.loadMore()
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ProgramListView()
    }
    .withDependencies(.preview)
}

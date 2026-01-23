//
//  DashboardView.swift
//  Nippardation
//
//  Main dashboard showing active program and next workout
//

import SwiftUI

struct DashboardView: View {

    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading && viewModel.activeProgram == nil {
                        ProgressView()
                            .padding(.top, 50)
                    } else if let program = viewModel.activeProgram {
                        // Active program content
                        activeProgramContent(program)
                    } else {
                        // No active program
                        noProgramContent
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.refreshAsync()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: TemplateListView()) {
                            Image(systemName: "doc.text")
                        }
                        NavigationLink(destination: ProgramListView()) {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadDashboard()
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

    // MARK: - Active Program Content

    @ViewBuilder
    private func activeProgramContent(_ program: Program) -> some View {
        VStack(spacing: 20) {
            // Next workout card
            if let nextWorkout = viewModel.nextWorkout,
               let template = viewModel.nextTemplate {
                NextWorkoutCard(
                    workout: nextWorkout,
                    template: template,
                    onStart: {
                        // TODO: Navigate to workout tracking view
                    }
                )
            }

            // Program progress
            programProgressSection(program)

            // All workouts carousel
            if !program.workouts.isEmpty {
                workoutCarouselSection(program)
            }
        }
    }

    @ViewBuilder
    private func programProgressSection(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(program.name)
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Cycle Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Day \(program.currentDayIndex + 1) of \(program.daysPerWeek)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(program.timesCompleted) cycles")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if !program.isIndefinite {
                ProgressView(value: program.progress)
                    .tint(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    @ViewBuilder
    private func workoutCarouselSection(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Program Workouts")
                .font(.headline)

            WorkoutCarousel(
                workouts: program.workouts,
                currentDayIndex: program.currentDayIndex,
                templates: viewModel.allTemplates
            )
        }
    }

    // MARK: - No Program Content

    private var noProgramContent: some View {
        ContentUnavailableView {
            Label("No Active Program", systemImage: "figure.run")
        } description: {
            Text("Start a program to see your next workout here")
        } actions: {
            NavigationLink(destination: ProgramListView()) {
                Text("Browse Programs")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Previews

#Preview {
    DashboardView()
        .withDependencies(.preview)
}

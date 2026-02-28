//
//  ProgramDetailView.swift
//  Nippardation
//
//  Detail view for displaying a single program
//

import SwiftUI

struct ProgramDetailView: View {

    let programServerId: String
    @StateObject private var viewModel: ProgramDetailViewModel
    @State private var showEditSheet = false
    @State private var showResetConfirmation = false

    init(programServerId: String) {
        self.programServerId = programServerId
        self._viewModel = StateObject(wrappedValue: ProgramDetailViewModel(programServerId: programServerId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.program == nil {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let program = viewModel.program {
                programContent(program)
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(viewModel.program?.name ?? "Program")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let program = viewModel.program {
                NavigationStack {
                    ProgramEditorView(existingProgram: program)
                }
            }
        }
        .alert("Reset Progress", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetProgram()
            }
        } message: {
            Text("This will reset your progress to Day 1 and clear your completion count.")
        }
        .onAppear {
            viewModel.loadProgram()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func programContent(_ program: Program) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                programHeader(program)

                // Workouts
                workoutsSection(program)

                // Actions
                actionsSection(program)
            }
            .padding(AppSpacing.md)
        }
    }

    @ViewBuilder
    private func programHeader(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let description = program.description {
                Text(description)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: AppSpacing.lg) {
                statItem(value: "\(program.daysPerWeek)", label: "days/week")
                statItem(value: program.durationString, label: "duration")
                statItem(value: "\(program.timesCompleted)", label: "completed")
            }

            if program.isActive {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Current Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !program.isIndefinite {
                        ProgressView(value: program.progress)
                            .tint(.appTheme)
                    }

                    Text("Day \(program.currentDayIndex + 1) of \(program.daysPerWeek)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, AppSpacing.xs)
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func workoutsSection(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Workouts")

            ForEach(program.workouts.sorted(by: { $0.dayNumber < $1.dayNumber })) { workout in
                // Compare by serverId to correctly identify the current workout
                // program.currentWorkout uses currentDayIndex as an array index, not a dayNumber match
                let isCurrentWorkout = program.currentWorkout?.serverId == workout.serverId
                workoutRow(workout, isNext: isCurrentWorkout && program.isActive)
            }
        }
    }

    @ViewBuilder
    private func workoutRow(_ workout: ProgramWorkout, isNext: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(workout.displayName)
                    .font(.subheadline)
                    .fontWeight(isNext ? .semibold : .regular)

                if let template = viewModel.templateFor(workout: workout) {
                    Text("\(template.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isNext {
                PillBadge(text: "Next", color: .appTheme)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.sm)
        .cardStyle(
            hasBorder: isNext,
            borderColor: Color.appTheme.opacity(0.3),
            backgroundColor: isNext ? Color.appTheme.opacity(0.1) : Color(.secondarySystemBackground)
        )
    }

    @ViewBuilder
    private func actionsSection(_ program: Program) -> some View {
        VStack(spacing: AppSpacing.sm) {
            if program.isActive {
                Button {
                    viewModel.advanceProgram()
                } label: {
                    Label("Advance to Next Day", systemImage: "arrow.forward.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reset Progress", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.deactivateProgram()
                } label: {
                    Label("Deactivate Program", systemImage: "pause.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    viewModel.activateProgram()
                } label: {
                    Label("Activate Program", systemImage: "play.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private func errorView(_ error: String) -> some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error)
        } actions: {
            Button("Retry") {
                viewModel.loadProgram()
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ProgramDetailView(programServerId: "prog_001")
    }
    .withDependencies(.preview)
}

//
//  SharePreviewView.swift
//  Nippardation
//
//  Preview screen shown when a user opens a share link
//

import SwiftUI

struct SharePreviewView: View {

    let token: String
    let onDismiss: () -> Void

    @StateObject private var viewModel = ImportViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    loadingView
                case .loaded:
                    if let item = viewModel.sharedItem {
                        previewContent(item)
                    }
                case .importing:
                    importingView
                case .imported:
                    successView
                case .error(let message):
                    errorView(message)
                }
            }
            .navigationTitle("Shared with You")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchShare(token: token)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .controlSize(.large)
            Text("Loading shared item...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Preview Content

    @ViewBuilder
    private func previewContent(_ item: SharedItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Shared by header
                sharedBySection(item)

                // Item details
                switch item.type {
                case .template:
                    if let template = item.template {
                        templatePreview(template)
                    }
                case .program:
                    if let program = item.program {
                        programPreview(program)
                    }
                }

                // Import button
                Button {
                    viewModel.importItem()
                } label: {
                    Label("Import to My Library", systemImage: "square.and.arrow.down")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(AppSpacing.md)
        }
    }

    private func sharedBySection(_ item: SharedItem) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "person.circle.fill")
                .font(.title)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Shared by \(item.sharedBy.displayName ?? item.sharedBy.handle)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(item.sharedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            PillBadge(
                text: item.type == .program ? "Program" : "Template",
                color: item.type == .program ? .blue : .appTheme
            )
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }

    private func templatePreview(_ template: Template) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(template.name)
                .font(.title2)
                .fontWeight(.bold)

            if let description = template.description {
                Text(description)
                    .foregroundColor(.secondary)
            }

            // Stats
            HStack(spacing: AppSpacing.lg) {
                statItem(value: "\(template.exerciseCount)", label: "Exercises")
                statItem(value: "\(template.totalWorkingSets)", label: "Working Sets")
                statItem(value: "\(template.estimatedDurationMinutes)m", label: "Est. Duration")
            }
            .padding(.vertical, AppSpacing.xs)

            // Exercise list
            if !template.exercises.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Exercises")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                        exerciseRow(exercise)
                    }
                }
            }
        }
    }

    private func programPreview(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(program.name)
                .font(.title2)
                .fontWeight(.bold)

            if let description = program.description {
                Text(description)
                    .foregroundColor(.secondary)
            }

            // Stats
            HStack(spacing: AppSpacing.lg) {
                statItem(value: "\(program.daysPerWeek)", label: "Days/Week")
                statItem(value: program.durationString, label: "Duration")
                statItem(value: "\(program.workouts.count)", label: "Workouts")
            }
            .padding(.vertical, AppSpacing.xs)

            // Workout list
            if !program.workouts.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Workouts")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(program.workouts.sorted(by: { $0.dayNumber < $1.dayNumber })) { workout in
                        workoutRow(workout)
                    }
                }
            }
        }
    }

    private func exerciseRow(_ exercise: TemplateExercise) -> some View {
        HStack {
            Text(exercise.displayName)
                .font(.subheadline)
            Spacer()
            Text(exercise.setSummary)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.sm)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.small)
    }

    private func workoutRow(_ workout: ProgramWorkout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.displayName)
                    .font(.subheadline)
                if let template = workout.template {
                    Text("\(template.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text("Day \(workout.dayNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.sm)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.small)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Importing

    private var importingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .controlSize(.large)
            Text("Importing...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Imported Successfully!")
                .font(.title2)
                .fontWeight(.bold)

            Text("The \(viewModel.sharedItem?.type == .program ? "program" : "template") has been added to your library.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, AppSpacing.md)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") {
                viewModel.retry()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

//
//  NextWorkoutCard.swift
//  Nippardation
//
//  Card showing the next scheduled workout
//

import SwiftUI

struct NextWorkoutCard: View {

    let workout: ProgramWorkout
    let template: Template
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Next Workout")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(workout.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                PillBadge(text: workout.dayIndicator, color: .appTheme)
            }

            // Exercise list preview
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(template.exercises.prefix(4)) { exercise in
                    HStack(spacing: AppSpacing.xs) {
                        Circle()
                            .fill(Color.appTheme.opacity(0.3))
                            .frame(width: 8, height: 8)

                        Text(exercise.exerciseLibraryItem?.name ?? "Exercise")
                            .font(.subheadline)

                        Spacer()

                        Text("\(exercise.workingSets) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if template.exercises.count > 4 {
                    Text("+ \(template.exercises.count - 4) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Stats row
            HStack(spacing: AppSpacing.md) {
                Label("\(template.exerciseCount) exercises", systemImage: "figure.strengthtraining.traditional")
                Label("\(template.totalWorkingSets) sets", systemImage: "number")
                Label("~\(template.estimatedDurationMinutes) min", systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Start button
            Button(action: onStart) {
                Text("Start Workout")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(AppSpacing.md)
        .gradientCardStyle()
    }
}

// MARK: - Previews

#Preview {
    NextWorkoutCard(
        workout: MockProgramRepository.samplePrograms[0].workouts[0],
        template: MockTemplateRepository.sampleTemplates[0],
        onStart: {}
    )
    .padding()
}

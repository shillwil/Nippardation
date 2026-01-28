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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Workout")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(workout.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                Text(workout.dayIndicator)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
            }

            // Exercise list preview
            VStack(alignment: .leading, spacing: 8) {
                ForEach(template.exercises.prefix(4)) { exercise in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
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
            HStack(spacing: 16) {
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
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
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

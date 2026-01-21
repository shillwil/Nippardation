//
//  WorkoutCarousel.swift
//  Nippardation
//
//  Horizontal carousel of workouts in a program
//

import SwiftUI

struct WorkoutCarousel: View {

    let workouts: [ProgramWorkout]
    let currentDayIndex: Int
    let templates: [Template]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(workouts.sorted(by: { $0.dayNumber < $1.dayNumber })) { workout in
                    workoutCard(workout, isNext: workout.dayNumber == currentDayIndex)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func workoutCard(_ workout: ProgramWorkout, isNext: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.dayIndicator)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isNext ? .white : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isNext ? Color.blue : Color.gray.opacity(0.2))
                    .cornerRadius(4)

                Spacer()

                if isNext {
                    Text("Next")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }

            Text(workout.displayName)
                .font(.headline)
                .lineLimit(1)

            if let template = templateFor(workout: workout) {
                Text("\(template.exerciseCount) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Show exercise names
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(template.exercises.prefix(3)) { exercise in
                        Text("• \(exercise.exerciseLibraryItem?.name ?? "Exercise")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("No exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 180)
        .background(isNext ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isNext ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }

    private func templateFor(workout: ProgramWorkout) -> Template? {
        // Check attached template first
        if let template = workout.template {
            return template
        }
        // Otherwise look in provided templates
        return templates.first { $0.serverId == workout.templateServerId }
    }
}

// MARK: - Previews

#Preview {
    WorkoutCarousel(
        workouts: MockProgramRepository.samplePrograms[0].workouts,
        currentDayIndex: 1,
        templates: MockTemplateRepository.sampleTemplates
    )
    .padding()
}

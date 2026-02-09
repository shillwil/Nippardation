//
//  WorkoutCarousel.swift
//  Nippardation
//
//  Horizontal carousel of workouts in a program
//

import SwiftUI

struct WorkoutCarousel: View {

    let workouts: [ProgramWorkout]
    let currentWorkoutServerId: String?
    let templates: [Template]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(workouts.sorted(by: { $0.dayNumber < $1.dayNumber })) { workout in
                    workoutCard(workout, isNext: workout.serverId == currentWorkoutServerId)
                }
            }
            .padding(.horizontal, AppSpacing.xxs)
            .padding(.vertical, AppSpacing.xs)
        }
    }

    @ViewBuilder
    private func workoutCard(_ workout: ProgramWorkout, isNext: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                PillBadge(
                    text: workout.dayIndicator,
                    color: isNext ? .appTheme : .gray,
                    style: isNext ? .filled : .tinted
                )

                Spacer()

                if isNext {
                    Text("Next")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.appTheme)
                }
            }

            Text(workout.displayName)
                .font(.headline)
                .lineLimit(1)

            if let template = templateFor(workout: workout) {
                Text("\(template.exerciseCount) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)

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
        .padding(AppSpacing.sm)
        .frame(width: 180)
        .cardStyle(
            cornerRadius: AppCornerRadius.large,
            hasBorder: isNext,
            borderColor: Color.appTheme.opacity(0.5)
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
        currentWorkoutServerId: MockProgramRepository.samplePrograms[0].currentWorkout?.serverId,
        templates: MockTemplateRepository.sampleTemplates
    )
    .padding()
}

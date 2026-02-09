//
//  HeroWorkoutCard.swift
//  Nippardation
//
//  Hero card showing the current/next workout from the active program
//

import SwiftUI

struct HeroWorkoutCard: View {
    let workout: ProgramWorkout?
    let template: Template?
    let programProgress: Double
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Top row: badge + progress ring
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    PillBadge(text: "Today's Focus", color: .appTheme, style: .tinted)

                    Text(workout?.displayName ?? "Ready to Train")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let template {
                        Text(muscleGroupSummary(for: template))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                CircularProgressView(
                    progress: programProgress,
                    progressColor: .appTheme,
                    size: 56
                )
            }

            // Info pills
            if let template {
                HStack(spacing: AppSpacing.sm) {
                    Label("\(template.exerciseCount) exercises", systemImage: "figure.strengthtraining.traditional")
                    Label("\(template.totalWorkingSets) sets", systemImage: "number")
                    Label("~\(template.estimatedDurationMinutes) min", systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            // Start button
            Button(action: onStart) {
                Text(workout != nil ? "Start Workout" : "Choose Workout")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(AppSpacing.md)
        .gradientCardStyle()
    }

    private func muscleGroupSummary(for template: Template) -> String {
        let muscles = template.exercises
            .compactMap { $0.exerciseLibraryItem }
            .flatMap { $0.primaryMuscles }
        var seen = Set<MuscleGroup>()
        let unique = muscles.filter { seen.insert($0).inserted }
        let names = unique.prefix(3).map { $0.rawValue.capitalized }
        if unique.count > 3 {
            return names.joined(separator: ", ") + " +\(unique.count - 3)"
        }
        return names.joined(separator: ", ")
    }
}

// MARK: - No Program Fallback

struct HeroWorkoutFallbackCard: View {
    let onChooseProgram: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(.appTheme)

            Text("No Active Program")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Start a program to see your next workout here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onChooseProgram) {
                Text("Browse Programs")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(AppSpacing.lg)
        .cardStyle(hasBorder: true)
    }
}

#Preview("With Workout") {
    HeroWorkoutCard(
        workout: MockProgramRepository.samplePrograms[0].currentWorkout,
        template: MockTemplateRepository.sampleTemplates.first,
        programProgress: 0.4,
        onStart: {}
    )
    .padding()
    .withDependencies(.preview)
}

#Preview("No Program") {
    HeroWorkoutFallbackCard(onChooseProgram: {})
        .padding()
}

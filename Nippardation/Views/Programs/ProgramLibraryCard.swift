//
//  ProgramLibraryCard.swift
//  Nippardation
//
//  Card component for displaying a program in the library grid
//

import SwiftUI

struct ProgramLibraryCard: View {

    let program: Program

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header: name + badges
            HStack(alignment: .top) {
                Text(program.name)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()

                HStack(spacing: AppSpacing.xxs) {
                    if program.isActive {
                        PillBadge(text: "Active", color: .green)
                    }

                    if program.isAiGenerated {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                }
            }

            // Description
            if let description = program.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Metadata pills
            HStack(spacing: AppSpacing.xs) {
                PillBadge(
                    text: program.frequencyString,
                    color: .blue,
                    style: .tinted
                )

                PillBadge(
                    text: program.durationString,
                    color: .purple,
                    style: .tinted
                )

                if program.timesCompleted > 0 {
                    PillBadge(
                        text: "\(program.timesCompleted)x completed",
                        color: .green,
                        style: .tinted
                    )
                }
            }

            // Workout tags
            if !program.workouts.isEmpty {
                workoutTags
            }

            // Progress bar for active programs
            if program.isActive && !program.isIndefinite {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    ProgressView(value: program.progress)
                        .tint(.green)

                    Text("Day \(program.currentDayIndex + 1) of \(program.daysPerWeek)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle(hasBorder: program.isActive, borderColor: Color.green.opacity(0.4))
    }

    // MARK: - Workout Tags

    private var workoutTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xxs) {
                ForEach(program.workouts.sorted(by: { $0.dayNumber < $1.dayNumber })) { workout in
                    Text(workout.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(AppCornerRadius.small)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Active Program") {
    ProgramLibraryCard(program: MockProgramRepository.samplePrograms[0])
        .padding()
}

#Preview("Inactive Program") {
    ProgramLibraryCard(program: MockProgramRepository.samplePrograms[1])
        .padding()
}

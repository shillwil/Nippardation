//
//  ExerciseSelectionRow.swift
//  Nippardation
//
//  Exercise row with icon circle and selection indicator for picker mode
//

import SwiftUI

struct ExerciseSelectionRow: View {
    let exercise: ExerciseLibraryItem
    let isSelected: Bool?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.sm) {
                // Icon circle
                IconCircle(
                    icon: iconForExercise,
                    color: colorForMuscle(exercise.primaryMuscles.first ?? .chest),
                    size: 44
                )

                // Details
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: AppSpacing.xs) {
                        Text(exercise.primaryMuscles.map { $0.rawValue.capitalized }.joined(separator: ", "))

                        if let equipment = exercise.equipment {
                            Text("·")
                            Text(equipment.displayName)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                if let selected = isSelected {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selected ? .appTheme : .gray)
                        .font(.title3)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, AppSpacing.xxs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconForExercise: String {
        guard let category = exercise.exerciseType else {
            return "figure.strengthtraining.traditional"
        }
        switch category {
        case .compound: return "figure.strengthtraining.traditional"
        case .isolation: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .plyometric: return "figure.jumprope"
        case .stretching: return "figure.flexibility"
        }
    }
}

#Preview {
    List {
        ExerciseSelectionRow(
            exercise: MockExerciseRepository.sampleExercises[0],
            isSelected: nil,
            onTap: {}
        )
        ExerciseSelectionRow(
            exercise: MockExerciseRepository.sampleExercises[1],
            isSelected: true,
            onTap: {}
        )
        ExerciseSelectionRow(
            exercise: MockExerciseRepository.sampleExercises[2],
            isSelected: false,
            onTap: {}
        )
    }
}

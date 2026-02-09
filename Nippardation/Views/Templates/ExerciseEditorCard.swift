//
//  ExerciseEditorCard.swift
//  Nippardation
//
//  Card component for displaying an exercise in the template editor
//

import SwiftUI

struct ExerciseEditorCard: View {

    let exercise: TemplateEditorViewModel.EditableExercise
    let onConfigure: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Top row: badge + name + gear
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    if let category = exercise.exerciseLibraryItem?.exerciseType {
                        PillBadge(
                            text: category.displayName,
                            color: colorForCategory(category),
                            style: .tinted
                        )
                    }

                    Text(exercise.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    if let muscles = exercise.exerciseLibraryItem?.primaryMuscles, !muscles.isEmpty {
                        Text(muscles.map { $0.rawValue.capitalized }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: onConfigure) {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                }
            }

            // Summary pills
            HStack(spacing: AppSpacing.sm) {
                if exercise.warmupSets > 0 {
                    summaryPill(icon: "flame", text: "\(exercise.warmupSets) warmup")
                }
                summaryPill(icon: "number", text: "\(exercise.workingSets) x \(exercise.targetReps)")
                summaryPill(icon: "timer", text: formatRestTime(exercise.restSeconds))
            }

            if !exercise.notes.isEmpty {
                Text(exercise.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(2)
            }
        }
        .padding(AppSpacing.sm)
        .cardStyle()
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Remove Exercise", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private func summaryPill(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }

    private func colorForCategory(_ category: ExerciseCategory) -> Color {
        switch category {
        case .compound: return .blue
        case .isolation: return .green
        case .cardio: return .orange
        case .plyometric: return .purple
        case .stretching: return .teal
        }
    }

    private func formatRestTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            }
            return "\(minutes):\(String(format: "%02d", remainingSeconds))"
        }
        return "\(seconds)s"
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: AppSpacing.sm) {
        ExerciseEditorCard(
            exercise: TemplateEditorViewModel.EditableExercise(
                orderIndex: 0,
                exerciseServerId: "ex_001",
                exerciseLibraryItem: MockExerciseRepository.sampleExercises[0],
                warmupSets: 2,
                workingSets: 4,
                targetReps: "6-8",
                restSeconds: 180,
                notes: "Focus on mind-muscle connection"
            ),
            onConfigure: {},
            onDelete: {}
        )
    }
    .padding()
}

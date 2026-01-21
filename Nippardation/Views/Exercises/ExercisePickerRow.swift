//
//  ExercisePickerRow.swift
//  Nippardation
//
//  Row component for displaying an exercise with optional selection
//

import SwiftUI

struct ExercisePickerRow: View {

    let exercise: ExerciseLibraryItem
    let isSelected: Bool?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                thumbnailView

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(exercise.primaryMuscles.map { $0.rawValue.capitalized }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        if let equipment = exercise.equipment {
                            Label(equipment.displayName, systemImage: "dumbbell")
                        }
                        if let difficulty = exercise.difficulty {
                            Label(difficulty.displayName, systemImage: "chart.bar")
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                if let selected = isSelected {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selected ? .blue : .gray)
                        .font(.title3)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailUrl = exercise.thumbnailUrl {
            AsyncImage(url: thumbnailUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
        } else {
            placeholderImage
                .frame(width: 60, height: 60)
        }
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.gray)
            )
            .cornerRadius(8)
    }
}

// MARK: - Previews

#Preview {
    List {
        ExercisePickerRow(
            exercise: MockExerciseRepository.sampleExercises[0],
            isSelected: nil,
            onTap: {}
        )
        ExercisePickerRow(
            exercise: MockExerciseRepository.sampleExercises[1],
            isSelected: true,
            onTap: {}
        )
        ExercisePickerRow(
            exercise: MockExerciseRepository.sampleExercises[2],
            isSelected: false,
            onTap: {}
        )
    }
}

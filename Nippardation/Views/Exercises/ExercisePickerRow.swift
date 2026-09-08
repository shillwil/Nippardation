//
//  ExercisePickerRow.swift
//  Nippardation
//
//  Exercise row with a 52pt thumbnail tile and optional selection check.
//

import SwiftUI

struct ExercisePickerRow: View {

    let exercise: ExerciseLibraryItem
    let isSelected: Bool?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: VoidSpace.s3) {
                ExerciseGlyphTile(exercise: exercise, size: VoidSize.tile)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)

                    Text(exercise.primaryMuscles.map { $0.rawValue.capitalized }.joined(separator: ", "))
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                        .lineLimit(1)

                    if !detail.isEmpty {
                        Text(detail)
                            .font(VoidFont.caption2)
                            .foregroundStyle(VoidColor.text3)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: VoidSpace.s2)

                if let selected = isSelected {
                    SelectionCheck(isOn: selected)
                } else {
                    VoidChevron()
                }
            }
            .padding(.horizontal, VoidSpace.insetText)
            .frame(minHeight: VoidSize.listRow)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidRowButtonStyle())
        .overlay(alignment: .bottom) {
            VoidHairline()
                .padding(.horizontal, VoidSpace.insetText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected == true ? [.isSelected] : [])
    }

    /// "Barbell · Intermediate"
    private var detail: String {
        [exercise.equipment?.displayName, exercise.difficulty?.displayName]
            .compactMap { $0 }
            .joined(separator: VoidFormat.dot)
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        VStack(spacing: 0) {
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
}

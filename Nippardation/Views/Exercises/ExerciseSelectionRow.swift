//
//  ExerciseSelectionRow.swift
//  Nippardation
//
//  Browser row content: 44pt glyph / thumbnail tile · name · "Chest · Barbell".
//  The List supplies everything interactive: a Button around it when picking one exercise,
//  the system selection circle when picking several.
//

import SwiftUI

struct ExerciseSelectionRow: View {
    let exercise: ExerciseLibraryItem

    var body: some View {
        HStack(spacing: VoidSpace.s3) {
            ExerciseGlyphTile(exercise: exercise)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(VoidFont.bodyStrong)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(1)

                Text(caption)
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.text2)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, VoidSpace.s1)
        .contentShape(Rectangle())
    }

    /// "Chest, Triceps · Barbell"
    private var caption: String {
        var parts = [exercise.primaryMuscles.map { $0.rawValue.capitalized }.joined(separator: ", ")]
        if let equipment = exercise.equipment {
            parts.append(equipment.displayName)
        }
        return parts.filter { !$0.isEmpty }.joined(separator: VoidFormat.dot)
    }
}

// MARK: - Glyph / thumbnail tile

/// Squared tile (radius 10, panel-2) showing the exercise thumbnail when there is one,
/// otherwise a glyph picked from the primary muscle / category.
struct ExerciseGlyphTile: View {
    let exercise: ExerciseLibraryItem
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let url = exercise.thumbnailUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        glyph
                    }
                }
            } else {
                glyph
            }
        }
        .frame(width: size, height: size)
        .background(VoidColor.panel2)
        .clipShape(RoundedRectangle(cornerRadius: VoidRadius.avatar, style: .continuous))
        .accessibilityHidden(true)
    }

    private var glyph: some View {
        Image(systemName: icon.systemName)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(VoidColor.text)
    }

    private var icon: VoidIcon {
        if let muscle = exercise.primaryMuscles.first {
            switch muscle {
            case .quads, .hamstrings, .glutes, .calves: return .workoutLegs
            case .back, .biceps: return .workoutPull
            case .chest, .triceps, .shoulders: return .workoutPush
            case .abs: return .workoutCore
            }
        }
        switch exercise.exerciseType {
        case .cardio?: return .workoutCardio
        case .plyometric?: return .workoutFullBody
        case .stretching?: return .workoutCore
        default: return .barbell
        }
    }
}

// MARK: - Previews

#Preview {
    List {
        ExerciseSelectionRow(exercise: MockExerciseRepository.sampleExercises[0])
            .listRowBackground(VoidColor.panel)
        ExerciseSelectionRow(exercise: MockExerciseRepository.sampleExercises[1])
            .listRowBackground(VoidColor.panel)
        ExerciseSelectionRow(exercise: MockExerciseRepository.sampleExercises[3])
            .listRowBackground(VoidColor.panel)
    }
    .listStyle(.insetGrouped)
    .voidScreen()
}

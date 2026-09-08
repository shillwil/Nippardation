//
//  ExerciseSelectionRow.swift
//  Nippardation
//
//  66pt browser row: 44pt glyph / thumbnail tile · name · "Chest · Barbell" · check or chevron.
//

import SwiftUI

struct ExerciseSelectionRow: View {
    let exercise: ExerciseLibraryItem
    let isSelected: Bool?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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

                Spacer(minLength: VoidSpace.s2)

                if let selected = isSelected {
                    SelectionCheck(isOn: selected)
                } else {
                    VoidChevron()
                }
            }
            .padding(.horizontal, VoidSpace.insetText)
            .frame(height: VoidSize.listRow)
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

// MARK: - Selection check

/// 22pt squared check (radius 6): plasma with an on-plasma check when on, text-3 outline when off.
struct SelectionCheck: View {
    let isOn: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: VoidRadius.mark, style: .continuous)
                .fill(isOn ? VoidColor.plasma : Color.clear)
            RoundedRectangle(cornerRadius: VoidRadius.mark, style: .continuous)
                .strokeBorder(isOn ? Color.clear : VoidColor.text3, lineWidth: 1)
            if isOn {
                Image(systemName: VoidIcon.check.systemName)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(VoidColor.onPlasma)
            }
        }
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        VStack(spacing: 0) {
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
                exercise: MockExerciseRepository.sampleExercises[3],
                isSelected: false,
                onTap: {}
            )
        }
    }
}

//
//  MuscleGroupFilterBar.swift
//  Nippardation
//
//  Horizontal row of 28pt squared muscle chips. Selected = panel-2 + text;
//  unselected = panel + hairline-2, text-2.
//

import SwiftUI

struct MuscleGroupFilterBar: View {
    let selectedMuscles: Set<MuscleGroup>
    let onToggle: (MuscleGroup?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VoidSpace.s2) {
                VoidSquareChip(text: "All", isSelected: selectedMuscles.isEmpty) {
                    onToggle(nil)
                }

                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    VoidSquareChip(text: muscle.rawValue, isSelected: selectedMuscles.contains(muscle)) {
                        onToggle(muscle)
                    }
                }
            }
            .padding(.horizontal, VoidSpace.insetCard)
        }
    }
}

// MARK: - Chip

/// 28pt squared chip (radius 8) with a Chakra label. Visual is 28pt; the hit area is padded to 44pt.
struct VoidSquareChip: View {
    let text: String
    var isSelected: Bool = false
    var trailingIcon: VoidIcon? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(text)
                    .voidChipLabel(isSelected ? VoidColor.text : VoidColor.text2)
                    .lineLimit(1)
                if let trailingIcon {
                    Image(systemName: trailingIcon.systemName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(VoidColor.text2)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: VoidSize.chip)
            .background(isSelected ? VoidColor.panel2 : VoidColor.panel)
            .clipShape(RoundedRectangle(cornerRadius: VoidRadius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VoidRadius.control, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : VoidColor.hairline2, lineWidth: 1)
            )
            .padding(.vertical, (VoidSize.hitMin - VoidSize.chip) / 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidPlainButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        VStack(spacing: 12) {
            MuscleGroupFilterBar(
                selectedMuscles: [.chest, .shoulders],
                onToggle: { _ in }
            )
            MuscleGroupFilterBar(
                selectedMuscles: [],
                onToggle: { _ in }
            )
        }
    }
}

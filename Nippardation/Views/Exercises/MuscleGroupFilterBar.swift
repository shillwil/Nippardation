//
//  MuscleGroupFilterBar.swift
//  Nippardation
//
//  Horizontal row of muscle filter chips: system button-style toggles, filled with plasma
//  while on. "All" is on when no muscle is picked; tapping it clears the picks.
//

import SwiftUI

struct MuscleGroupFilterBar: View {
    let selectedMuscles: Set<MuscleGroup>
    let onToggle: (MuscleGroup?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VoidSpace.s2) {
                ChipToggle(title: "All", isOn: selectedMuscles.isEmpty) { _ in
                    onToggle(nil)
                }

                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    ChipToggle(
                        title: muscle.rawValue.capitalized,
                        isOn: selectedMuscles.contains(muscle)
                    ) { _ in
                        onToggle(muscle)
                    }
                }
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.vertical, VoidSpace.s1)
        }
    }
}

// MARK: - Chip

/// A chip is the system button-style `Toggle`: it fills with plasma while on and reports its
/// on/off state to VoiceOver. The label switches to on-plasma ink while on so it stays
/// legible on the fill; the control keeps the system font.
struct ChipToggle: View {
    let title: String
    let isOn: Bool
    /// Called with the state the user asked for. The owner decides what it means (a filter
    /// flips, a preset only ever turns on).
    let onChange: (Bool) -> Void

    var body: some View {
        Toggle(isOn: Binding(
            get: { isOn },
            set: { onChange($0) }
        )) {
            Text(title)
                .foregroundStyle(isOn ? VoidColor.onPlasma : VoidColor.text)
                .lineLimit(1)
        }
        .toggleStyle(.button)
        .tint(VoidColor.plasma)
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

//
//  MuscleGroupFilterBar.swift
//  Nippardation
//
//  Horizontal scrolling muscle group filter tabs
//

import SwiftUI

struct MuscleGroupFilterBar: View {
    let selectedMuscles: Set<MuscleGroup>
    let onToggle: (MuscleGroup?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                // "All" pill
                filterPill(
                    label: "All",
                    isActive: selectedMuscles.isEmpty,
                    action: { onToggle(nil) }
                )

                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    filterPill(
                        label: muscle.rawValue.capitalized,
                        isActive: selectedMuscles.contains(muscle),
                        action: { onToggle(muscle) }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private func filterPill(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isActive ? .semibold : .regular)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(isActive ? Color.appTheme.opacity(0.15) : Color(.tertiarySystemBackground))
                .foregroundColor(isActive ? .appTheme : .primary)
                .cornerRadius(AppCornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
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

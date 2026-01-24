//
//  ExerciseFilterSheet.swift
//  Nippardation
//
//  Filter sheet for exercise browsing
//

import SwiftUI

struct ExerciseFilterSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var filter: ExerciseFilter
    let onApply: (ExerciseFilter) -> Void

    init(
        filter: ExerciseFilter,
        onApply: @escaping (ExerciseFilter) -> Void
    ) {
        self._filter = State(initialValue: filter)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                // Muscle groups
                muscleGroupsSection

                // Equipment
                equipmentSection

                // Difficulty
                difficultySection

                // Movement pattern
                movementPatternSection
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        filter.reset()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(filter)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Sections

    private var muscleGroupsSection: some View {
        Section("Muscle Groups") {
            ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                filterToggle(
                    label: muscle.rawValue.capitalized,
                    isSelected: filter.muscleGroups.contains(muscle),
                    onToggle: { selected in
                        if selected {
                            filter.muscleGroups.insert(muscle)
                        } else {
                            filter.muscleGroups.remove(muscle)
                        }
                    }
                )
            }
        }
    }

    private var equipmentSection: some View {
        Section("Equipment") {
            ForEach(Equipment.allCases, id: \.self) { equip in
                filterToggle(
                    label: equip.displayName,
                    isSelected: filter.equipment.contains(equip),
                    onToggle: { selected in
                        if selected {
                            filter.equipment.insert(equip)
                        } else {
                            filter.equipment.remove(equip)
                        }
                    }
                )
            }
        }
    }

    private var difficultySection: some View {
        Section("Difficulty") {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                filterToggle(
                    label: difficulty.displayName,
                    isSelected: filter.difficulty == difficulty,
                    onToggle: { selected in
                        filter.difficulty = selected ? difficulty : nil
                    }
                )
            }
        }
    }

    private var movementPatternSection: some View {
        Section("Movement Pattern") {
            ForEach(MovementPattern.allCases, id: \.self) { pattern in
                filterToggle(
                    label: pattern.displayName,
                    isSelected: filter.movementPattern == pattern,
                    onToggle: { selected in
                        filter.movementPattern = selected ? pattern : nil
                    }
                )
            }
        }
    }

    // MARK: - Filter Toggle

    private func filterToggle(
        label: String,
        isSelected: Bool,
        onToggle: @escaping (Bool) -> Void
    ) -> some View {
        Button {
            onToggle(!isSelected)
        } label: {
            HStack {
                Text(label)
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ExerciseFilterSheet(
        filter: ExerciseFilter(),
        onApply: { _ in }
    )
}

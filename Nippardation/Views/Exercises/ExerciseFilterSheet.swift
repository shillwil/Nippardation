//
//  ExerciseFilterSheet.swift
//  Nippardation
//
//  Filter sheet for exercise browsing: a system Form with a checkmark row per option.
//  Muscle groups and equipment pick any number; difficulty and movement pattern pick one,
//  and tapping the picked row again clears it.
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
                muscleGroupsSection
                equipmentSection
                difficultySection
                movementPatternSection
            }
            .tint(VoidColor.plasmaInk)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Reset clears the choices in place; it doesn't dismiss, so it isn't a cancel.
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        filter.reset()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(filter)
                        dismiss()
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var muscleGroupsSection: some View {
        Section("Muscle groups") {
            ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                FilterOptionRow(
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
                FilterOptionRow(
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
                FilterOptionRow(
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
        Section("Movement pattern") {
            ForEach(MovementPattern.allCases, id: \.self) { pattern in
                FilterOptionRow(
                    label: pattern.displayName,
                    isSelected: filter.movementPattern == pattern,
                    onToggle: { selected in
                        filter.movementPattern = selected ? pattern : nil
                    }
                )
            }
        }
    }
}

// MARK: - Option row

/// A Form row that toggles one option, with the system checkmark in the tint colour when on.
private struct FilterOptionRow: View {
    let label: String
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button {
            onToggle(!isSelected)
        } label: {
            HStack {
                Text(label)
                    .font(VoidFont.body)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: VoidIcon.check.systemName)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Previews

#Preview {
    ExerciseFilterSheet(
        filter: ExerciseFilter(),
        onApply: { _ in }
    )
}

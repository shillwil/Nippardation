//
//  ExerciseFilterSheet.swift
//  Nippardation
//
//  Filter sheet for exercise browsing. Void sheet: panel background, eyebrow sections,
//  44pt rows with hairlines and a plasma check on the selected options.
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
            ScrollView {
                VStack(alignment: .leading, spacing: VoidSpace.s5) {
                    muscleGroupsSection
                    equipmentSection
                    difficultySection
                    movementPatternSection
                }
                .padding(.horizontal, VoidSpace.insetText)
                .padding(.top, VoidSpace.s3)
                .padding(.bottom, VoidSpace.s6)
            }
            .scrollContentBackground(.hidden)
            .background(VoidColor.panel.ignoresSafeArea())
            .toolbarBackground(VoidColor.panel, for: .navigationBar)
            .tint(VoidColor.plasma)
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
        .voidSheet()
    }

    // MARK: - Sections

    private var muscleGroupsSection: some View {
        section("Muscle groups") {
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
        section("Equipment") {
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
        section("Difficulty") {
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
        section("Movement pattern") {
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

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .voidEyebrowSm()
                .padding(.bottom, VoidSpace.s1)
            content()
        }
    }
}

// MARK: - Option row

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
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(VoidColor.plasma)
                }
            }
            .frame(height: VoidSize.pill)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidRowButtonStyle())
        .overlay(alignment: .bottom) {
            VoidHairline()
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

//
//  AIWizardStep3EquipmentView.swift
//  Nippardation
//
//  Step 3: experience level and equipment.
//

import SwiftUI

struct AIWizardStep3EquipmentView: View {
    @ObservedObject var viewModel: AIWizardViewModel

    private var showEquipment: Bool {
        AppConfiguration.shared.sendEquipmentToAI
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoidSpace.s6) {
                AISectionHeader(
                    "Your setup",
                    subtitle: showEquipment
                        ? "Your experience level and the equipment you have."
                        : "Your experience level."
                )
                .padding(.horizontal, VoidSpace.s1)

                // Experience level
                VStack(alignment: .leading, spacing: VoidSpace.s2) {
                    WizardSectionLabel(title: "Experience")

                    VoidSegmentedControl(
                        items: AIExperienceLevel.allCases,
                        label: { $0.displayName },
                        selection: $viewModel.experienceLevel
                    )
                }

                if showEquipment {
                    VStack(alignment: .leading, spacing: VoidSpace.s2) {
                        WizardSectionLabel(
                            title: "Equipment",
                            trailing: "\(VoidFormat.pad2(viewModel.selectedEquipment.count)) selected"
                        )

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: VoidSpace.s2),
                            GridItem(.flexible(), spacing: VoidSpace.s2),
                            GridItem(.flexible(), spacing: VoidSpace.s2),
                            GridItem(.flexible(), spacing: VoidSpace.s2)
                        ], spacing: VoidSpace.s2) {
                            ForEach(AIEquipment.allCases) { equipment in
                                equipmentCard(equipment)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.vertical, VoidSpace.s2)
        }
    }

    // MARK: - Subviews

    private func equipmentCard(_ equipment: AIEquipment) -> some View {
        let isSelected = viewModel.selectedEquipment.contains(equipment)

        return WizardOptionCard(isSelected: isSelected, checkInset: 6, action: {
            if isSelected {
                viewModel.selectedEquipment.remove(equipment)
            } else {
                viewModel.selectedEquipment.insert(equipment)
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: equipment.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(VoidColor.text)
                    .frame(height: 24)
                    .accessibilityHidden(true)

                Text(equipment.displayName)
                    .font(VoidFont.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, VoidSpace.s1)
        }
        .accessibilityLabel(equipment.displayName)
    }
}

#Preview {
    NavigationStack {
        AIWizardStep3EquipmentView(viewModel: AIWizardViewModel())
            .voidScreen()
    }
    .withDependencies(.preview)
}

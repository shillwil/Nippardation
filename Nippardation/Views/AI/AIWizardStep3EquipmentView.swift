//
//  AIWizardStep3EquipmentView.swift
//  Nippardation
//
//  Step 3: experience level (a segmented control) and equipment (a switch per item).
//

import SwiftUI

struct AIWizardStep3EquipmentView: View {
    @ObservedObject var viewModel: AIWizardViewModel

    private var showEquipment: Bool {
        AppConfiguration.shared.sendEquipmentToAI
    }

    var body: some View {
        Form {
            Section {
                Picker("Experience", selection: $viewModel.experienceLevel) {
                    ForEach(AIExperienceLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            } header: {
                Text("Experience")
            } footer: {
                if !showEquipment {
                    Text("Your experience level.")
                }
            }
            .wizardFormRows()

            if showEquipment {
                Section {
                    ForEach(AIEquipment.allCases) { equipment in
                        Toggle(isOn: equipmentBinding(equipment)) {
                            Label {
                                Text(equipment.displayName)
                                    .foregroundStyle(VoidColor.text)
                            } icon: {
                                Image(systemName: equipment.icon)
                            }
                        }
                    }
                } header: {
                    Text("Equipment")
                } footer: {
                    Text(equipmentFooter)
                }
                .wizardFormRows()
            }
        }
    }

    // MARK: - Helpers

    private var equipmentFooter: String {
        let count = viewModel.selectedEquipment.count
        return count == 0 ? "Pick at least one." : "\(count) selected"
    }

    private func equipmentBinding(_ equipment: AIEquipment) -> Binding<Bool> {
        Binding(
            get: { viewModel.selectedEquipment.contains(equipment) },
            set: { isOn in
                if isOn {
                    viewModel.selectedEquipment.insert(equipment)
                } else {
                    viewModel.selectedEquipment.remove(equipment)
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        AIWizardStep3EquipmentView(viewModel: AIWizardViewModel())
            .voidScreen()
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
    }
    .withDependencies(.preview)
}

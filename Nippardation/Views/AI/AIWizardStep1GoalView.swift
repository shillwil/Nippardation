//
//  AIWizardStep1GoalView.swift
//  Nippardation
//
//  Step 1: training goal (a checkmark list) and split preference (a menu, with Custom opening
//  a free-text description).
//

import SwiftUI

struct AIWizardStep1GoalView: View {
    @ObservedObject var viewModel: AIWizardViewModel

    /// The split menu's selection: a suggestion, or nil for Custom. Choosing a suggestion writes its
    /// name into the prompt; switching back to Custom clears it for the user's own words.
    private var splitSelection: Binding<AISplitSuggestion?> {
        Binding(
            get: { viewModel.selectedSplitSuggestion },
            set: { newValue in
                if let newValue {
                    viewModel.selectedSplitSuggestion = newValue
                    viewModel.inspirationSource = newValue.rawValue
                } else if viewModel.selectedSplitSuggestion != nil {
                    viewModel.selectedSplitSuggestion = nil
                    viewModel.inspirationSource = ""
                }
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("Goal", selection: $viewModel.selectedGoal) {
                    ForEach(AITrainingGoal.allCases) { goal in
                        goalLabel(goal)
                            .tag(goal)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Goal")
            } footer: {
                Text("Pick a training focus.")
            }
            .wizardFormRows()

            Section {
                Picker("Split", selection: splitSelection) {
                    ForEach(AISplitSuggestion.allCases) { suggestion in
                        Text(suggestion.rawValue)
                            .tag(Optional(suggestion))
                    }
                    Text("Custom")
                        .tag(AISplitSuggestion?.none)
                }
                .pickerStyle(.menu)
                // The menu shows its value as tinted text; plasma text is too faint on a light panel.
                .tint(VoidColor.text2)

                if viewModel.selectedSplitSuggestion == nil {
                    TextField("Describe it, e.g. Arnold split", text: $viewModel.inspirationSource)
                        .foregroundStyle(VoidColor.text)
                }
            } header: {
                Text("Preferred split")
            } footer: {
                Text("Pick a split, or choose Custom and describe your own. Leave it blank to let the AI decide.")
            }
            .wizardFormRows()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Rows

    private func goalLabel(_ goal: AITrainingGoal) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.displayName)
                    .foregroundStyle(VoidColor.text)
                Text(goal.subtitle)
                    .font(.footnote)
                    .foregroundStyle(VoidColor.text2)
            }
        } icon: {
            Image(systemName: goal.icon)
        }
    }
}

#Preview {
    NavigationStack {
        AIWizardStep1GoalView(viewModel: AIWizardViewModel())
            .voidScreen()
            .navigationTitle("Goal")
            .navigationBarTitleDisplayMode(.inline)
    }
    .withDependencies(.preview)
}

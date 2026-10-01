//
//  AIWizardStep1GoalView.swift
//  Nippardation
//
//  Step 1: training goal and split preference, both checkmark lists with a line on each option
//  (Custom opens a free-text description).
//

import SwiftUI

struct AIWizardStep1GoalView: View {
    @ObservedObject var viewModel: AIWizardViewModel

    /// The split list's selection: a suggestion, or nil for Custom. Choosing a suggestion writes its
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
                // A checkmark list, like Goal, so every split carries its one-line explanation.
                Picker("Split", selection: splitSelection) {
                    ForEach(AISplitSuggestion.allCases) { suggestion in
                        splitLabel(suggestion.displayName, subtitle: suggestion.subtitle, icon: suggestion.icon)
                            .tag(Optional(suggestion))
                    }
                    splitLabel("Custom", subtitle: "Describe your own, or leave it blank to let the AI decide.", icon: "pencil")
                        .tag(AISplitSuggestion?.none)
                }
                .pickerStyle(.inline)
                .labelsHidden()

                if viewModel.selectedSplitSuggestion == nil {
                    TextField("Describe it, e.g. Arnold split", text: $viewModel.inspirationSource)
                        .foregroundStyle(VoidColor.text)
                }
            } header: {
                Text("Preferred split")
            } footer: {
                Text("A split is how your week's training is divided across days.")
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

    private func splitLabel(_ title: String, subtitle: String, icon: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(VoidColor.text)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(VoidColor.text2)
            }
        } icon: {
            Image(systemName: icon)
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

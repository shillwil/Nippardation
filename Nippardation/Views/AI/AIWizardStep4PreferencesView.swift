//
//  AIWizardStep4PreferencesView.swift
//  Nippardation
//
//  Step 4: generations left, free-text preferences, workout reuse (a switch, then a switch per
//  workout, up to seven), and optional strength data behind a disclosure group.
//

import SwiftUI

struct AIWizardStep4PreferencesView: View {
    @ObservedObject var viewModel: AIWizardViewModel
    @State private var showStrengthSection = false

    /// The AI refreshes at most this many existing workouts (`AIWizardViewModel.toggleTemplateSelection`).
    private let maxReusedWorkouts = 7

    var body: some View {
        Form {
            quotaSection
            preferencesSection
            reuseSection
            strengthSection
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Quota

    @ViewBuilder
    private var quotaSection: some View {
        if let status = viewModel.generationStatus {
            Section {
                LabeledContent("AI plans left") {
                    Text("\(status.generationsRemaining) of \(status.generationsLimit)")
                        .foregroundStyle(status.hasRemaining ? VoidColor.text2 : VoidColor.warning)
                }
            } footer: {
                if !status.hasRemaining {
                    Text("Resets on \(status.resetsAtFormatted).")
                        .foregroundStyle(VoidColor.warning)
                }
            }
            .wizardFormRows()
        } else if viewModel.isLoadingQuota {
            Section {
                LabeledContent("AI plans left") {
                    ProgressView()
                }
            }
            .wizardFormRows()
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section {
            TextField(
                "e.g. focus on compounds, avoid deadlifts, more arm volume",
                text: $viewModel.freeTextPreferences,
                axis: .vertical
            )
            .lineLimit(3...6)
            .foregroundStyle(VoidColor.text)
        } header: {
            Text("Preferences")
        } footer: {
            HStack(alignment: .firstTextBaseline) {
                Text("Optional. Anything specific you want.")
                Spacer(minLength: VoidSpace.s3)
                Text("\(viewModel.freeTextPreferences.count) / 500")
                    .monospacedDigit()
                    .foregroundStyle(viewModel.freeTextPreferences.count > 500 ? VoidColor.warning : VoidColor.text2)
            }
        }
        .wizardFormRows()
    }

    // MARK: - Reuse workouts

    private var reuseSection: some View {
        Section {
            Toggle(isOn: $viewModel.reuseTemplates) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reuse existing workouts")
                            .foregroundStyle(VoidColor.text)
                        Text("Pick up to \(maxReusedWorkouts) for the AI to refresh instead of creating new ones.")
                            .font(.footnote)
                            .foregroundStyle(VoidColor.text2)
                    }
                } icon: {
                    Image(systemName: VoidIcon.swap.systemName)
                }
            }
            .onChange(of: viewModel.reuseTemplates) { _, isOn in
                if isOn && viewModel.availableTemplates.isEmpty {
                    viewModel.loadTemplates()
                }
                if !isOn {
                    viewModel.selectedTemplateIds.removeAll()
                }
            }

            if viewModel.reuseTemplates {
                if viewModel.isLoadingTemplates {
                    LabeledContent("Loading workouts") {
                        ProgressView()
                    }
                } else if viewModel.availableTemplates.isEmpty {
                    Text("No workouts found.")
                        .foregroundStyle(VoidColor.text2)
                } else {
                    ForEach(viewModel.availableTemplates) { template in
                        templateReuseRow(template)
                    }
                }
            }
        } header: {
            Text("Reuse workouts")
        } footer: {
            if viewModel.reuseTemplates && !viewModel.availableTemplates.isEmpty {
                Text("\(viewModel.selectedTemplateIds.count) of \(maxReusedWorkouts) picked")
            }
        }
        .wizardFormRows()
    }

    private func templateReuseRow(_ template: Template) -> some View {
        let isSelected = viewModel.selectedTemplateIds.contains(template.serverId)
        let atMax = viewModel.selectedTemplateIds.count >= maxReusedWorkouts

        return Toggle(isOn: templateBinding(template)) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: VoidSpace.s1) {
                        Text(template.name)
                            .foregroundStyle(VoidColor.text)
                            .lineLimit(1)
                        if template.isAiGenerated {
                            Image(systemName: VoidIcon.sparkle.systemName)
                                .font(.caption)
                                .foregroundStyle(VoidColor.plasma)
                                .accessibilityLabel("AI generated")
                        }
                    }
                    Text("\(template.exerciseCount) exercise\(template.exerciseCount == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundStyle(VoidColor.text2)
                }
            } icon: {
                Image(systemName: VoidIcon.workoutGlyph(for: template.name).systemName)
            }
        }
        // At the cap, only the picked workouts can still be switched (off).
        .disabled(!isSelected && atMax)
    }

    private func templateBinding(_ template: Template) -> Binding<Bool> {
        Binding(
            get: { viewModel.selectedTemplateIds.contains(template.serverId) },
            set: { isOn in
                if isOn != viewModel.selectedTemplateIds.contains(template.serverId) {
                    viewModel.toggleTemplateSelection(template.serverId)
                }
            }
        )
    }

    // MARK: - Strength data

    private var strengthSection: some View {
        Section {
            DisclosureGroup(isExpanded: $showStrengthSection) {
                if viewModel.isLoadingProfile {
                    LabeledContent("Loading saved lifts") {
                        ProgressView()
                    }
                } else {
                    ForEach($viewModel.strengthEntries) { $entry in
                        strengthEntryRow(entry: $entry)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Remove", role: .destructive) {
                                    removeStrengthEntry(id: entry.id)
                                }
                                .tint(.red) // the plasma tint would otherwise recolour it
                            }
                    }

                    if viewModel.strengthEntries.count < 20 {
                        Button {
                            viewModel.addStrengthEntry()
                        } label: {
                            Label {
                                Text("Add exercise")
                                    .foregroundStyle(VoidColor.text)
                            } icon: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(VoidColor.plasma)
                            }
                        }
                    }
                }
            } label: {
                LabeledContent("Strength data", value: "Optional")
            }
        } footer: {
            Text(strengthFooter)
        }
        .wizardFormRows()
    }

    private var strengthFooter: String {
        let purpose = "Enter your current lifts to personalize exercise selection and weights."
        guard showStrengthSection, !viewModel.strengthEntries.isEmpty else { return purpose }
        return purpose + " Swipe an exercise to remove it."
    }

    private func strengthEntryRow(entry: Binding<StrengthDataEntry>) -> some View {
        VStack(spacing: VoidSpace.s2) {
            VoidTextField(placeholder: "Exercise name", text: entry.exerciseName, autocapitalization: .words)

            HStack(spacing: VoidSpace.s2) {
                WizardDecimalField(placeholder: "Weight", value: entry.weight)
                Picker("Unit", selection: entry.unit) {
                    Text("lb").tag("lb")
                    Text("kg").tag("kg")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }

            HStack(spacing: VoidSpace.s2) {
                WizardIntField(placeholder: "Reps", value: entry.reps)
                Text("×")
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text2)
                    .accessibilityHidden(true)
                WizardIntField(placeholder: "Sets", value: entry.sets)
            }
        }
        .padding(.vertical, VoidSpace.s2)
    }

    private func removeStrengthEntry(id: UUID) {
        if let index = viewModel.strengthEntries.firstIndex(where: { $0.id == id }) {
            viewModel.removeStrengthEntry(at: IndexSet(integer: index))
        }
    }
}

#Preview {
    NavigationStack {
        AIWizardStep4PreferencesView(viewModel: AIWizardViewModel())
            .voidScreen()
            .navigationTitle("Fine-tune")
            .navigationBarTitleDisplayMode(.inline)
    }
    .withDependencies(.preview)
}

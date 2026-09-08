//
//  AIWizardStep4PreferencesView.swift
//  Nippardation
//
//  Step 4: preferences, workout reuse, optional strength data.
//

import SwiftUI

struct AIWizardStep4PreferencesView: View {
    @ObservedObject var viewModel: AIWizardViewModel
    @State private var showStrengthSection = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoidSpace.s6) {
                AISectionHeader("Fine-tune", subtitle: "Add preferences, then generate the plan.")
                    .padding(.horizontal, VoidSpace.s1)

                quotaSection
                preferencesSection
                reuseSection
                strengthSection
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.vertical, VoidSpace.s2)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Quota

    @ViewBuilder
    private var quotaSection: some View {
        if let status = viewModel.generationStatus {
            VStack(alignment: .leading, spacing: VoidSpace.s2) {
                AIQuotaBadge(remaining: status.generationsRemaining, limit: status.generationsLimit)
                if !status.hasRemaining {
                    WizardHelperText(text: "Resets on \(status.resetsAtFormatted).", color: VoidColor.warning)
                }
            }
            .padding(.horizontal, VoidSpace.s1)
        } else if viewModel.isLoadingQuota {
            HStack(spacing: VoidSpace.s2) {
                ProgressView()
                    .tint(VoidColor.plasma)
                    .controlSize(.small)
                Text("Checking quota")
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text2)
            }
            .padding(.horizontal, VoidSpace.s1)
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s2) {
            WizardSectionLabel(title: "Preferences")
            WizardHelperText(text: "Optional. Anything specific you want.")

            WizardTextArea(
                placeholder: "e.g. focus on compounds, avoid deadlifts, more arm volume",
                text: $viewModel.freeTextPreferences
            )

            HStack {
                Spacer()
                Text("\(viewModel.freeTextPreferences.count) / 500")
                    .font(VoidFont.caption2)
                    .monospacedDigit()
                    .foregroundStyle(viewModel.freeTextPreferences.count > 500 ? VoidColor.warning : VoidColor.text2)
            }
            .padding(.horizontal, VoidSpace.s1)
        }
    }

    // MARK: - Reuse workouts

    private var reuseSection: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s2) {
            WizardSectionLabel(title: "Reuse workouts")

            WizardOptionCard(isSelected: viewModel.reuseTemplates, action: {
                viewModel.reuseTemplates.toggle()
            }) {
                HStack(spacing: VoidSpace.s3) {
                    WizardGlyphSquare(icon: .swap)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reuse existing workouts")
                            .font(VoidFont.bodyStrong)
                            .foregroundStyle(VoidColor.text)
                        Text("Pick up to 7 for the AI to refresh instead of creating new ones.")
                            .font(VoidFont.caption2)
                            .foregroundStyle(VoidColor.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: VoidSpace.s5)
                }
                .padding(14)
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
                    HStack(spacing: VoidSpace.s2) {
                        ProgressView()
                            .tint(VoidColor.plasma)
                            .controlSize(.small)
                        Text("Loading workouts")
                            .font(VoidFont.caption)
                            .foregroundStyle(VoidColor.text2)
                    }
                    .padding(.horizontal, VoidSpace.s1)
                } else if viewModel.availableTemplates.isEmpty {
                    WizardHelperText(text: "No workouts found.")
                } else {
                    ForEach(viewModel.availableTemplates) { template in
                        templateReuseRow(template)
                    }
                }
            }
        }
    }

    private func templateReuseRow(_ template: Template) -> some View {
        let isSelected = viewModel.selectedTemplateIds.contains(template.serverId)
        let atMax = viewModel.selectedTemplateIds.count >= 7

        return WizardOptionCard(isSelected: isSelected, isEnabled: isSelected || !atMax, action: {
            viewModel.toggleTemplateSelection(template.serverId)
        }) {
            HStack(spacing: VoidSpace.s3) {
                WizardGlyphSquare(icon: VoidIcon.workoutGlyph(for: template.name))

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                    Text(VoidFormat.exercises(template.exerciseCount)).voidReadout()
                }

                Spacer(minLength: VoidSpace.s2)

                if template.isAiGenerated {
                    Image(systemName: VoidIcon.sparkle.systemName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(VoidColor.plasma)
                        .accessibilityLabel("AI generated")
                }
            }
            .padding(14)
        }
    }

    // MARK: - Strength data

    private var strengthSection: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s2) {
            Button {
                showStrengthSection.toggle()
            } label: {
                HStack(spacing: VoidSpace.s2) {
                    Text("Strength data").voidEyebrowSm()
                    Text("Optional").voidEyebrowSm(VoidColor.text3)
                    Spacer()
                    VoidChevron()
                        .rotationEffect(.degrees(showStrengthSection ? -90 : 90))
                }
                .padding(.horizontal, VoidSpace.s1)
                .frame(minHeight: VoidSize.hitMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(VoidPlainButtonStyle())
            .accessibilityLabel("Strength data, optional")
            .accessibilityValue(showStrengthSection ? "Expanded" : "Collapsed")

            if showStrengthSection {
                WizardHelperText(text: "Enter your current lifts to personalize exercise selection and weights.")

                if viewModel.isLoadingProfile {
                    HStack(spacing: VoidSpace.s2) {
                        ProgressView()
                            .tint(VoidColor.plasma)
                            .controlSize(.small)
                        Text("Loading saved profile")
                            .font(VoidFont.caption)
                            .foregroundStyle(VoidColor.text2)
                    }
                    .padding(.horizontal, VoidSpace.s1)
                } else {
                    ForEach($viewModel.strengthEntries) { $entry in
                        strengthEntryRow(entry: $entry) {
                            if let index = viewModel.strengthEntries.firstIndex(where: { $0.id == entry.id }) {
                                viewModel.removeStrengthEntry(at: IndexSet(integer: index))
                            }
                        }
                    }

                    if viewModel.strengthEntries.count < 20 {
                        VoidPillButton(title: "Add exercise") {
                            viewModel.addStrengthEntry()
                        }
                    }
                }
            }
        }
    }

    private func strengthEntryRow(entry: Binding<StrengthDataEntry>, onRemove: @escaping () -> Void) -> some View {
        VStack(spacing: VoidSpace.s2) {
            HStack(spacing: VoidSpace.s2) {
                VoidTextField(placeholder: "Exercise name", text: entry.exerciseName, autocapitalization: .words)

                Button(action: onRemove) {
                    Image(systemName: VoidIcon.close.systemName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(VoidColor.text2)
                        .frame(width: VoidSize.hitMin, height: VoidSize.hitMin)
                }
                .buttonStyle(VoidPlainButtonStyle())
                .accessibilityLabel("Remove exercise")
            }

            HStack(spacing: VoidSpace.s2) {
                WizardDecimalField(placeholder: "Weight", value: entry.weight)
                VoidSegmentedControl(items: ["lb", "kg"], label: { $0 }, selection: entry.unit)
            }

            HStack(spacing: VoidSpace.s2) {
                WizardIntField(placeholder: "Reps", value: entry.reps)
                Text("×")
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text2)
                WizardIntField(placeholder: "Sets", value: entry.sets)
            }
        }
        .padding(14)
        .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2)
    }
}

#Preview {
    NavigationStack {
        AIWizardStep4PreferencesView(viewModel: AIWizardViewModel())
            .voidScreen()
    }
    .withDependencies(.preview)
}

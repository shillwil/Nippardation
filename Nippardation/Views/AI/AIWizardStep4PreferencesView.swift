//
//  AIWizardStep4PreferencesView.swift
//  Nippardation
//
//  Step 4: Free-text preferences, optional strength data, and generate trigger
//

import SwiftUI

struct AIWizardStep4PreferencesView: View {
    @ObservedObject var viewModel: AIWizardViewModel
    @State private var showStrengthSection = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                AISectionHeader("Fine-Tune & Generate", subtitle: "Add preferences and generate your program")

                // Quota display
                if let status = viewModel.generationStatus {
                    AIQuotaBadge(remaining: status.generationsRemaining, limit: status.generationsLimit)

                    if !status.hasRemaining {
                        Text("Resets on \(status.resetsAtFormatted)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } else if viewModel.isLoadingQuota {
                    HStack(spacing: AppSpacing.xs) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking quota...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Free-text preferences
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Additional Preferences")
                        .font(.headline)

                    Text("Optional. Describe anything specific you want.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("e.g., focus on compounds, avoid deadlifts, more arm volume...", text: $viewModel.freeTextPreferences, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)

                    HStack {
                        Spacer()
                        Text("\(viewModel.freeTextPreferences.count)/500")
                            .font(.caption2)
                            .foregroundColor(
                                viewModel.freeTextPreferences.count > 500 ? .red : .secondary
                            )
                    }
                }

                Divider()
                    .padding(.vertical, AppSpacing.xs)

                // Strength data section (expandable)
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Button {
                        withAnimation { showStrengthSection.toggle() }
                    } label: {
                        HStack {
                            Text("Strength Data")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("(Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: showStrengthSection ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if showStrengthSection {
                        Text("Enter your current lifts to personalize exercise selection and weights.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if viewModel.isLoadingProfile {
                            ProgressView("Loading saved profile...")
                                .font(.caption)
                        } else {
                            ForEach($viewModel.strengthEntries) { $entry in
                                strengthEntryRow(entry: $entry)
                            }
                            .onDelete { viewModel.removeStrengthEntry(at: $0) }

                            if viewModel.strengthEntries.count < 20 {
                                Button {
                                    viewModel.addStrengthEntry()
                                } label: {
                                    Label("Add Exercise", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(AIColors.accent)
                                }
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Strength Entry Row

    private func strengthEntryRow(entry: Binding<StrengthDataEntry>) -> some View {
        VStack(spacing: AppSpacing.xs) {
            TextField("Exercise name", text: entry.exerciseName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xxs) {
                    TextField("Weight", value: entry.weight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .frame(width: 70)

                    Picker("", selection: entry.unit) {
                        Text("lb").tag("lb")
                        Text("kg").tag("kg")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                }

                HStack(spacing: AppSpacing.xxs) {
                    TextField("Reps", value: entry.reps, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 50)
                    Text("x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Sets", value: entry.sets, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 50)
                }
            }
        }
        .padding(AppSpacing.sm)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        AIWizardStep4PreferencesView(viewModel: AIWizardViewModel())
    }
    .withDependencies(.preview)
}

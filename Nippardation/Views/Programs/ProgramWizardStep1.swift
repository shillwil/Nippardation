//
//  ProgramWizardStep1.swift
//  Nippardation
//
//  Step 1 of the program wizard: basic info and schedule
//

import SwiftUI

struct ProgramWizardStep1: View {
    @ObservedObject var viewModel: ProgramEditorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Step title
                VStack(spacing: AppSpacing.xs) {
                    Text("The Basics")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Name your program and set up the schedule")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Program name
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Program Name")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "pencil.line")
                            .foregroundColor(.appTheme)

                        TextField("e.g., PPL Hypertrophy", text: $viewModel.name)
                            .textFieldStyle(.plain)
                    }
                    .padding(AppSpacing.sm)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(AppCornerRadius.medium)
                }

                // Duration
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Duration")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: AppSpacing.md) {
                        Toggle("", isOn: Binding(
                            get: { !viewModel.isIndefinite },
                            set: { viewModel.isIndefinite = !$0 }
                        ))
                        .labelsHidden()

                        VStack(alignment: .leading) {
                            Text(viewModel.isIndefinite ? "Ongoing" : "\(viewModel.durationWeeks ?? 8) Weeks")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(viewModel.isIndefinite ? "No end date" : "Fixed duration program")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(AppSpacing.sm)
                    .cardStyle()

                    if !viewModel.isIndefinite {
                        Stepper(
                            "Duration: \(viewModel.durationWeeks ?? 8) weeks",
                            value: Binding(
                                get: { viewModel.durationWeeks ?? 8 },
                                set: { viewModel.durationWeeks = $0 }
                            ),
                            in: 1...52
                        )
                        .padding(AppSpacing.sm)
                        .cardStyle()
                    }
                }

                // Training days
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Training Days")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    DaySelectorGrid(selectedDays: $viewModel.selectedDays)
                        .padding(AppSpacing.sm)
                        .cardStyle()
                }
            }
            .padding(AppSpacing.md)
        }
    }
}

#Preview {
    ProgramWizardStep1(viewModel: ProgramEditorViewModel())
        .withDependencies(.preview)
}

//
//  ProgramWizardStep3.swift
//  Nippardation
//
//  Step 3 of the program wizard: review and create
//

import SwiftUI

struct ProgramWizardStep3: View {
    @ObservedObject var viewModel: ProgramEditorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Step title
                VStack(spacing: AppSpacing.xs) {
                    Text("Review Your Program")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Make sure everything looks good")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Program summary
                summaryCard

                // Schedule overview
                scheduleCard

                // Stats
                statsRow
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Program")

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(viewModel.name)
                    .font(.headline)

                if !viewModel.description.isEmpty {
                    Text(viewModel.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: AppSpacing.md) {
                    PillBadge(
                        text: "\(trainingDayCount) days/week",
                        color: .appTheme,
                        style: .tinted
                    )

                    if viewModel.isIndefinite {
                        PillBadge(text: "Ongoing", color: .green, style: .tinted)
                    } else {
                        PillBadge(
                            text: "\(viewModel.durationWeeks ?? 8) weeks",
                            color: .purple,
                            style: .tinted
                        )
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }

    // MARK: - Schedule Card

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Weekly Schedule")

            ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                let isRest = viewModel.restDays.contains(index)
                HStack {
                    Text("Day \(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 44, alignment: .leading)

                    if isRest {
                        Text("Rest Day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text(workout.templateName ?? "Unassigned")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    Image(systemName: isRest ? "moon.fill" : "checkmark.circle.fill")
                        .foregroundColor(isRest ? .purple : .green)
                        .font(.caption)
                }
                .padding(.vertical, AppSpacing.xxs)

                if index < viewModel.workouts.count - 1 {
                    Divider()
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: AppSpacing.sm) {
            statItem(value: "\(trainingDayCount)", label: "Training Days")
            statItem(value: "\(restDayCount)", label: "Rest Days")
            statItem(value: "\(totalExercises)", label: "Exercises")
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.sm)
        .cardStyle()
    }

    // MARK: - Computed

    private var trainingDayCount: Int {
        viewModel.workouts.count - restDayCount
    }

    private var restDayCount: Int {
        viewModel.restDays.count
    }

    private var totalExercises: Int {
        var count = 0
        for (index, workout) in viewModel.workouts.enumerated() {
            if viewModel.restDays.contains(index) { continue }
            if let templateId = workout.templateServerId,
               let template = viewModel.availableTemplates.first(where: { $0.serverId == templateId }) {
                count += template.exerciseCount
            }
        }
        return count
    }
}

#Preview {
    ProgramWizardStep3(viewModel: ProgramEditorViewModel())
        .withDependencies(.preview)
}

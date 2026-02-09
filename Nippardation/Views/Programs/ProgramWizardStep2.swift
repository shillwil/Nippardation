//
//  ProgramWizardStep2.swift
//  Nippardation
//
//  Step 2 of the program wizard: weekly schedule builder
//

import SwiftUI

struct ProgramWizardStep2: View {
    @ObservedObject var viewModel: ProgramEditorViewModel
    @State private var selectedWorkoutIndex: Int?
    @State private var showTemplatePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Step title
                VStack(spacing: AppSpacing.xs) {
                    Text("Build Your Schedule")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Assign templates to each training day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Progress
                progressBar

                // Day cards
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                        let isRest = viewModel.restDays.contains(index)
                        DayScheduleCard(
                            dayNumber: dayNumberForWorkout(index),
                            dayLabel: workout.dayLabel,
                            templateName: workout.templateName,
                            exerciseCount: exerciseCount(for: workout),
                            isRest: isRest,
                            onSelectTemplate: {
                                selectedWorkoutIndex = index
                                showTemplatePicker = true
                            },
                            onToggleRest: {
                                viewModel.toggleRestDay(at: index)
                            }
                        )
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplateSelectorSheet(
                templates: viewModel.availableTemplates,
                isLoading: viewModel.isLoadingTemplates,
                onSelect: { template in
                    if let index = selectedWorkoutIndex {
                        viewModel.setTemplate(template, for: index)
                    }
                }
            )
        }
    }

    // MARK: - Subviews

    private var progressBar: some View {
        let assigned = viewModel.workouts.enumerated().filter { index, workout in
            viewModel.restDays.contains(index) || workout.templateServerId != nil
        }.count
        let total = viewModel.workouts.count

        return VStack(spacing: AppSpacing.xxs) {
            ProgressView(value: Double(assigned), total: Double(max(total, 1)))
                .tint(.appTheme)

            Text("\(assigned)/\(total) days configured")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private func dayNumberForWorkout(_ index: Int) -> Int {
        let sortedDays = viewModel.selectedDays.sorted()
        if index < sortedDays.count {
            return sortedDays[index]
        }
        return index
    }

    private func exerciseCount(for workout: ProgramEditorViewModel.EditableWorkout) -> Int? {
        guard let templateId = workout.templateServerId else { return nil }
        return viewModel.availableTemplates.first { $0.serverId == templateId }?.exerciseCount
    }
}

#Preview {
    ProgramWizardStep2(viewModel: ProgramEditorViewModel())
        .withDependencies(.preview)
}

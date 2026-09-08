//
//  ProgramWizardStep2.swift
//  Nippardation
//
//  Step 2 of the plan wizard: assign a workout to each training day.
//

import SwiftUI

struct ProgramWizardStep2: View {
    @ObservedObject var viewModel: ProgramEditorViewModel
    @State private var selectedWorkoutIndex: Int?
    @State private var showTemplatePicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoidSpace.s6) {
                WizardStepHeading(title: "Your schedule", caption: "Pick a workout for each training day, or make it a rest day.")

                VStack(alignment: .leading, spacing: 10) {
                    WizardSectionLabel(
                        title: "Schedule",
                        trailing: "DAYS \(VoidFormat.ratio(assignedCount, viewModel.workouts.count))"
                    )

                    VoidProgressBar(progress: Double(assignedCount) / Double(max(viewModel.workouts.count, 1)))
                        .padding(.horizontal, VoidSpace.s1)

                    ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                        DayScheduleCard(
                            dayNumber: dayNumberForWorkout(index),
                            dayIndex: index,
                            templateName: workout.templateName,
                            exerciseCount: exerciseCount(for: workout),
                            isRest: viewModel.restDays.contains(index),
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
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.vertical, VoidSpace.s2)
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

    // MARK: - Helpers

    private var assignedCount: Int {
        viewModel.workouts.enumerated().filter { index, workout in
            viewModel.restDays.contains(index) || workout.templateServerId != nil
        }.count
    }

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
        .voidScreen()
        .withDependencies(.preview)
}

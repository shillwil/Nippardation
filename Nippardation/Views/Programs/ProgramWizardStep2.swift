//
//  ProgramWizardStep2.swift
//  Nippardation
//
//  Step 2 of the plan wizard: assign a workout to each training day, or make it a rest day.
//  The step's title lives in the navigation bar; the days are rows of an inset-grouped list whose
//  header counts the days set.
//

import SwiftUI

struct ProgramWizardStep2: View {
    @ObservedObject var viewModel: ProgramEditorViewModel
    @State private var selectedWorkoutIndex: Int?
    @State private var showTemplatePicker = false

    var body: some View {
        List {
            Section {
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
            } header: {
                HStack {
                    Text("Days")
                    Spacer()
                    Text("\(assignedCount) of \(viewModel.workouts.count) set")
                }
                .accessibilityElement(children: .combine)
            } footer: {
                Text("Pick a workout for each training day, or make it a rest day.")
            }
            .wizardFormRows()
        }
        .listStyle(.insetGrouped)
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
    NavigationStack {
        ProgramWizardStep2(viewModel: ProgramEditorViewModel())
            .voidScreen()
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
    }
    .withDependencies(.preview)
}

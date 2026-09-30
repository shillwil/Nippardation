//
//  ProgramWizardStep3.swift
//  Nippardation
//
//  Step 3 of the plan wizard: review before creating, as a grouped list — the plan, then its schedule.
//

import SwiftUI

struct ProgramWizardStep3: View {
    @ObservedObject var viewModel: ProgramEditorViewModel

    var body: some View {
        List {
            Section {
                summary
            } header: {
                Text("Plan")
            }
            .wizardFormRows()

            Section {
                ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                    scheduleRow(workout, index: index)
                }
            } header: {
                HStack {
                    Text("Schedule")
                    Spacer()
                    Text("\(viewModel.workouts.count) day\(viewModel.workouts.count == 1 ? "" : "s")")
                }
            } footer: {
                Text(scheduleFooter)
            }
            .wizardFormRows()
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s2) {
            Text(viewModel.name)
                .font(VoidFont.title)
                .foregroundStyle(VoidColor.text)
                .lineLimit(2)

            if !viewModel.description.isEmpty {
                Text(viewModel.description)
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text2)
            }

            Text(VoidFormat.readout([
                "\(trainingDayCount) DAYS / WK",
                viewModel.isIndefinite ? "ONGOING" : VoidFormat.weeks(viewModel.durationWeeks ?? 8)
            ]))
            .voidReadout()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, VoidSpace.s2)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Schedule

    private func scheduleRow(_ workout: ProgramEditorViewModel.EditableWorkout, index: Int) -> some View {
        let isRest = viewModel.restDays.contains(index)

        return HStack(spacing: VoidSpace.s3) {
            if isRest {
                WizardGlyphSquare(icon: .rest, color: VoidColor.text3)
            } else {
                WizardGlyphSquare(icon: VoidIcon.workoutGlyph(for: workout.templateName))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(VoidFormat.readout(["DAY \(VoidFormat.pad2(index + 1))", dayOfWeekLabel(index)]))
                    .voidEyebrowSm(isRest ? VoidColor.text3 : VoidColor.text2)

                if isRest {
                    Text("Rest day")
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text3)
                } else {
                    Text(workout.templateName ?? "No workout")
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(workout.templateName == nil ? VoidColor.warning : VoidColor.text)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: VoidSpace.s2)

            if !isRest && workout.templateName != nil {
                Image(systemName: VoidIcon.check.systemName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(VoidColor.plasma)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, VoidSpace.s1)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Computed

    private var scheduleFooter: String {
        let exercises = totalExercises
        return "\(trainingDayCount) training · \(restDayCount) rest · \(exercises) exercise\(exercises == 1 ? "" : "s")"
    }

    private func dayOfWeekLabel(_ index: Int) -> String? {
        let sortedDays = viewModel.selectedDays.sorted()
        guard index < sortedDays.count else { return nil }
        let day = sortedDays[index]
        guard day >= 0 && day < VoidFormat.weekStripLabels.count else { return nil }
        return VoidFormat.weekStripLabels[day]
    }

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
    NavigationStack {
        ProgramWizardStep3(viewModel: ProgramEditorViewModel())
            .voidScreen()
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
    }
    .withDependencies(.preview)
}

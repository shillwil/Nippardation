//
//  ProgramWizardStep3.swift
//  Nippardation
//
//  Step 3 of the plan wizard: review before creating.
//

import SwiftUI

struct ProgramWizardStep3: View {
    @ObservedObject var viewModel: ProgramEditorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoidSpace.s6) {
                WizardStepHeading(title: "Review", caption: "Check the plan before you create it.")

                summaryPanel

                VStack(alignment: .leading, spacing: 10) {
                    WizardSectionLabel(title: "Schedule", trailing: VoidFormat.days(viewModel.workouts.count))
                    schedulePanel
                }

                Text(VoidFormat.readout([
                    "\(VoidFormat.pad2(trainingDayCount)) TRAINING",
                    "\(VoidFormat.pad2(restDayCount)) REST",
                    VoidFormat.exercises(totalExercises)
                ]))
                .voidReadout()
                .frame(maxWidth: .infinity)
                .padding(.top, VoidSpace.s1)
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.vertical, VoidSpace.s2)
        }
    }

    // MARK: - Summary

    private var summaryPanel: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s2) {
            Text("Plan").voidEyebrowSm()

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
        .padding(VoidSpace.s4)
        .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline)
    }

    // MARK: - Schedule

    private var schedulePanel: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.workouts.enumerated()), id: \.element.id) { index, workout in
                let isRest = viewModel.restDays.contains(index)

                HStack(spacing: VoidSpace.s3) {
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
                .frame(height: VoidSize.listRow)
                .accessibilityElement(children: .combine)

                if index < viewModel.workouts.count - 1 {
                    VoidHairline()
                }
            }
        }
        .padding(.horizontal, 14)
        .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline)
    }

    // MARK: - Computed

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
    ProgramWizardStep3(viewModel: ProgramEditorViewModel())
        .voidScreen()
        .withDependencies(.preview)
}

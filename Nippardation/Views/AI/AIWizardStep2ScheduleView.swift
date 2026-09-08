//
//  AIWizardStep2ScheduleView.swift
//  Nippardation
//
//  Step 2: days per week and session length.
//

import SwiftUI

struct AIWizardStep2ScheduleView: View {
    @ObservedObject var viewModel: AIWizardViewModel

    private let durations = [30, 45, 60, 75, 90, 120]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoidSpace.s6) {
                AISectionHeader("Your schedule", subtitle: "How often and how long you can train.")
                    .padding(.horizontal, VoidSpace.s1)

                // Days per week
                VStack(alignment: .leading, spacing: VoidSpace.s2) {
                    WizardSectionLabel(title: "Days per week")

                    HStack(spacing: VoidSpace.s2) {
                        ForEach(1...7, id: \.self) { day in
                            WizardSquareTile(
                                label: "\(day)",
                                isSelected: viewModel.daysPerWeek == day,
                                style: .number,
                                accessibilityLabel: "\(day) day\(day == 1 ? "" : "s") per week"
                            ) {
                                viewModel.daysPerWeek = day
                            }
                        }
                    }

                    WizardHelperText(text: "\(viewModel.daysPerWeek) training day\(viewModel.daysPerWeek == 1 ? "" : "s") per week")
                }

                // Session length
                VStack(alignment: .leading, spacing: VoidSpace.s2) {
                    WizardSectionLabel(title: "Session length")

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        ForEach(durations, id: \.self) { minutes in
                            durationCard(minutes)
                        }
                    }
                }
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.vertical, VoidSpace.s2)
        }
    }

    // MARK: - Subviews

    private func durationCard(_ minutes: Int) -> some View {
        WizardOptionCard(isSelected: viewModel.sessionDurationMinutes == minutes, action: {
            viewModel.sessionDurationMinutes = minutes
        }) {
            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(VoidFont.title)
                    .monospacedDigit()
                    .foregroundStyle(VoidColor.text)
                Text("min").voidEyebrowSm()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .accessibilityLabel("\(minutes) minutes")
    }
}

#Preview {
    NavigationStack {
        AIWizardStep2ScheduleView(viewModel: AIWizardViewModel())
            .voidScreen()
    }
    .withDependencies(.preview)
}

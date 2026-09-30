//
//  AIWizardStep2ScheduleView.swift
//  Nippardation
//
//  Step 2: days per week (a stepper) and session length (a menu).
//

import SwiftUI

struct AIWizardStep2ScheduleView: View {
    @ObservedObject var viewModel: AIWizardViewModel

    private let durations = [30, 45, 60, 75, 90, 120]

    var body: some View {
        Form {
            // A stepper and a menu rather than segmented controls: seven and six segments are more
            // than a phone-width control should hold, and VoiceOver reads a bare segment number with
            // no unit. Both rows read "label, value".
            Section {
                Stepper(value: $viewModel.daysPerWeek, in: 1...7) {
                    LabeledContent("Days per week", value: "\(viewModel.daysPerWeek)")
                }

                Picker("Session length", selection: $viewModel.sessionDurationMinutes) {
                    ForEach(durations, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.menu)
                // The menu shows its value in the tint; text-2 keeps it quiet, like the split menu
                // on the Goal step.
                .tint(VoidColor.text2)
            } footer: {
                Text("How often and how long you can train.")
            }
            .wizardFormRows()
        }
    }
}

#Preview {
    NavigationStack {
        AIWizardStep2ScheduleView(viewModel: AIWizardViewModel())
            .voidScreen()
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
    }
    .withDependencies(.preview)
}

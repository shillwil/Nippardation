//
//  ProgramWizardStep1.swift
//  Nippardation
//
//  Step 1 of the plan wizard: name, length (a switch, then a weeks stepper) and training days.
//

import SwiftUI

struct ProgramWizardStep1: View {
    @ObservedObject var viewModel: ProgramEditorViewModel

    private var weeks: Binding<Int> {
        Binding(
            get: { viewModel.durationWeeks ?? 8 },
            set: { viewModel.durationWeeks = min(max($0, 1), 52) }
        )
    }

    /// The switch reads "Fixed length"; the view model stores the opposite, `isIndefinite`.
    private var isFixedLength: Binding<Bool> {
        Binding(
            get: { !viewModel.isIndefinite },
            set: { viewModel.isIndefinite = !$0 }
        )
    }

    private var weeksText: String {
        let count = weeks.wrappedValue
        return "\(count) week\(count == 1 ? "" : "s")"
    }

    private var lengthFooter: String {
        viewModel.isIndefinite ? "Ongoing: the plan has no end date." : "The plan ends after \(weeksText)."
    }

    var body: some View {
        Form {
            Section {
                TextField("e.g. Upper / Lower", text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(VoidColor.text)
            } header: {
                Text("Plan name")
            }
            .wizardFormRows()

            Section {
                Toggle("Fixed length", isOn: isFixedLength)

                if !viewModel.isIndefinite {
                    Stepper(value: weeks, in: 1...52) {
                        LabeledContent("Duration", value: weeksText)
                    }
                }
            } header: {
                Text("Length")
            } footer: {
                Text(lengthFooter)
            }
            .wizardFormRows()

            Section {
                // The day strip is a row of tiles, so it sits on the hull rather than in a panel row.
                // Its tiles are buttons: a non-automatic button style keeps each one answering only
                // its own taps inside a list row.
                DaySelectorGrid(selectedDays: $viewModel.selectedDays)
                    // Prominent: a selected day is a solid plasma fill with on-plasma ink. Under
                    // .bordered it was a faint wash that read as less selected than the others.
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: VoidSpace.s1, leading: 0, bottom: VoidSpace.s1, trailing: 0))
            } header: {
                Text("Training days")
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    NavigationStack {
        ProgramWizardStep1(viewModel: ProgramEditorViewModel())
            .voidScreen()
            .navigationTitle("Basics")
            .navigationBarTitleDisplayMode(.inline)
    }
    .withDependencies(.preview)
}

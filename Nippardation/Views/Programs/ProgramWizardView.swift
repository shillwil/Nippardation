//
//  ProgramWizardView.swift
//  Nippardation
//
//  Three-step wizard for building a new plan. Owns its NavigationStack (presented as a sheet):
//  each step pushes the next, so the system back button and edge swipe step back.
//

import SwiftUI

struct ProgramWizardView: View {
    /// The wizard's steps, in order. The first is the stack's root; the rest are pushed.
    enum Step: Int, CaseIterable, Hashable {
        case basics
        case schedule
        case review

        var title: String {
            switch self {
            case .basics: return "Basics"
            case .schedule: return "Schedule"
            case .review: return "Review"
            }
        }

        var next: Step? { Step(rawValue: rawValue + 1) }
    }

    @StateObject private var viewModel = ProgramEditorViewModel()
    @Environment(\.dismiss) private var dismiss

    /// The pushed steps. Always exactly the steps after the first up to the one on screen.
    @State private var path: [Step] = []

    var body: some View {
        NavigationStack(path: $path) {
            stepScreen(.basics)
                .navigationDestination(for: Step.self) { step in
                    stepScreen(step)
                }
        }
        .onAppear {
            viewModel.loadTemplates()
        }
        .onChange(of: viewModel.savedProgram) { _, newValue in
            if newValue != nil { dismiss() }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.error ?? "Something went wrong.")
        }
    }

    private func stepScreen(_ step: Step) -> some View {
        ProgramWizardStepScreen(
            step: step,
            viewModel: viewModel,
            onContinue: { advance(from: step) },
            onCancel: { dismiss() }
        )
    }

    /// Pushes the step after `step`. Setting the whole path (rather than appending) keeps a double
    /// tap on Continue from pushing the same step twice.
    private func advance(from step: Step) {
        guard let next = step.next else { return }
        path = Array(Step.allCases.dropFirst().prefix(next.rawValue))
    }
}

// MARK: - Step screen

/// One step: its content, plus the shared step chrome with the step's primary action. Observes the
/// view model itself so Continue / Create track validity and saving on a pushed screen.
private struct ProgramWizardStepScreen: View {
    let step: ProgramWizardView.Step
    @ObservedObject var viewModel: ProgramEditorViewModel
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        content
            .voidScreen()
            .wizardStep(
                step.title,
                step: step.rawValue,
                of: ProgramWizardView.Step.allCases.count,
                onCancel: onCancel
            ) {
                if step.next == nil {
                    VoidCTAButton(
                        title: "Create plan",
                        isEnabled: isValid,
                        isLoading: viewModel.isSaving
                    ) {
                        viewModel.save()
                    }
                } else {
                    VoidCTAButton(title: "Continue", isEnabled: isValid, action: onContinue)
                }
            }
            // While the plan saves, nothing on the step (Cancel included) takes input and there is
            // no stepping back; the Create button shows the progress.
            .disabled(viewModel.isSaving)
            .navigationBarBackButtonHidden(viewModel.isSaving)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .basics:
            ProgramWizardStep1(viewModel: viewModel)
        case .schedule:
            ProgramWizardStep2(viewModel: viewModel)
        case .review:
            ProgramWizardStep3(viewModel: viewModel)
        }
    }

    private var isValid: Bool {
        switch step {
        case .basics: return viewModel.isStep1Valid
        case .schedule: return viewModel.isStep2Valid
        case .review: return viewModel.isValid
        }
    }
}

#Preview {
    ProgramWizardView()
        .withDependencies(.preview)
}

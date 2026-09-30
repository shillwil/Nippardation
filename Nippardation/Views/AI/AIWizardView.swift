//
//  AIWizardView.swift
//  Nippardation
//
//  Four-step wizard for generating a plan with AI. Owns its NavigationStack (presented full screen):
//  each step pushes the next, so the system back button and edge swipe step back.
//

import SwiftUI

struct AIWizardView: View {
    /// The wizard's steps, in order. The first is the stack's root; the rest are pushed.
    enum Step: Int, CaseIterable, Hashable {
        case goal
        case schedule
        case setup
        case fineTune

        var title: String {
            switch self {
            case .goal: return "Goal"
            case .schedule: return "Schedule"
            case .setup: return "Setup"
            case .fineTune: return "Fine-tune"
            }
        }

        var next: Step? { Step(rawValue: rawValue + 1) }
    }

    @StateObject private var viewModel = AIWizardViewModel()
    @Environment(\.dismiss) private var dismiss

    /// The pushed steps. Always exactly the steps after the first up to the one on screen.
    @State private var path: [Step] = []
    @State private var showPreview = false

    var body: some View {
        NavigationStack(path: $path) {
            stepScreen(.goal)
                .navigationDestination(for: Step.self) { step in
                    stepScreen(step)
                }
        }
        .accessibilityHidden(viewModel.isGenerating)
        .overlay {
            if viewModel.isGenerating {
                AIGeneratingView(
                    messageIndex: viewModel.loadingMessageIndex,
                    messages: viewModel.loadingMessages,
                    onCancel: { viewModel.cancelGeneration() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.12), value: viewModel.isGenerating)
        .onAppear {
            viewModel.loadQuota()
            viewModel.loadStrengthProfile()
        }
        .onChange(of: viewModel.generationComplete) { _, complete in
            if complete {
                showPreview = true
            }
        }
        .fullScreenCover(isPresented: $showPreview) {
            if let program = viewModel.generatedProgram {
                NavigationStack {
                    GeneratedProgramPreviewView(
                        program: program,
                        metadata: viewModel.generationMetadata,
                        reusedTemplateIds: viewModel.reusedTemplateIds,
                        onSave: {
                            dismiss()
                        },
                        onDiscard: {
                            viewModel.discardGeneratedProgram()
                            showPreview = false
                        }
                    )
                }
            }
        }
        .alert("Generation failed", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            if viewModel.errorIsRetryable {
                Button("Try again") {
                    viewModel.clearError()
                    viewModel.generate()
                }
                Button("Cancel", role: .cancel) { viewModel.clearError() }
            } else {
                Button("OK") { viewModel.clearError() }
            }
        } message: {
            Text(viewModel.error ?? "Something went wrong.")
        }
    }

    private func stepScreen(_ step: Step) -> some View {
        AIWizardStepScreen(
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

/// One step: its form, plus the shared step chrome with the step's primary action. Observes the
/// view model itself so Continue / Generate track validity on a pushed screen.
private struct AIWizardStepScreen: View {
    let step: AIWizardView.Step
    @ObservedObject var viewModel: AIWizardViewModel
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        content
            .voidScreen()
            .wizardStep(
                step.title,
                step: step.rawValue,
                of: AIWizardView.Step.allCases.count,
                onCancel: onCancel
            ) {
                if step.next == nil {
                    VoidCTAButton(
                        title: "Generate plan",
                        isEnabled: viewModel.canGenerate,
                        isLoading: viewModel.isGenerating
                    ) {
                        viewModel.generate()
                    }
                } else {
                    VoidCTAButton(title: "Continue", isEnabled: isValid, action: onContinue)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .goal:
            AIWizardStep1GoalView(viewModel: viewModel)
        case .schedule:
            AIWizardStep2ScheduleView(viewModel: viewModel)
        case .setup:
            AIWizardStep3EquipmentView(viewModel: viewModel)
        case .fineTune:
            AIWizardStep4PreferencesView(viewModel: viewModel)
        }
    }

    private var isValid: Bool {
        switch step {
        case .goal: return viewModel.isStep1Valid
        case .schedule: return viewModel.isStep2Valid
        case .setup: return viewModel.isStep3Valid
        case .fineTune: return viewModel.isStep4Valid
        }
    }
}

#Preview {
    AIWizardView()
        .withDependencies(.preview)
}

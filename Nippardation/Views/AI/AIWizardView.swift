//
//  AIWizardView.swift
//  Nippardation
//
//  Four-step wizard for generating a plan with AI. Owns its NavigationStack (presented full screen).
//

import SwiftUI

struct AIWizardView: View {
    @StateObject private var viewModel = AIWizardViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var showPreview = false
    private let totalSteps = 4

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AIStepIndicator(totalSteps: totalSteps, currentStep: currentStep)
                    .padding(.top, VoidSpace.s3)
                    .padding(.bottom, VoidSpace.s4)

                Group {
                    switch currentStep {
                    case 0:
                        AIWizardStep1GoalView(viewModel: viewModel)
                    case 1:
                        AIWizardStep2ScheduleView(viewModel: viewModel)
                    case 2:
                        AIWizardStep3EquipmentView(viewModel: viewModel)
                    case 3:
                        AIWizardStep4PreferencesView(viewModel: viewModel)
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                WizardFooter(showBack: currentStep > 0, onBack: { currentStep -= 1 }) {
                    if currentStep < totalSteps - 1 {
                        VoidCTAButton(title: "Continue", isEnabled: isCurrentStepValid) {
                            currentStep += 1
                        }
                    } else {
                        AIGradientButton("Generate plan", isDisabled: !viewModel.canGenerate) {
                            viewModel.generate()
                        }
                    }
                }
            }
            .voidScreen()
            .navigationTitle("AI plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                viewModel.loadQuota()
                viewModel.loadStrengthProfile()
            }
            .overlay {
                if viewModel.isGenerating {
                    AIGeneratingView(
                        messageIndex: viewModel.loadingMessageIndex,
                        messages: viewModel.loadingMessages,
                        onCancel: { viewModel.cancelGeneration() }
                    )
                }
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
    }

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0: return viewModel.isStep1Valid
        case 1: return viewModel.isStep2Valid
        case 2: return viewModel.isStep3Valid
        case 3: return viewModel.isStep4Valid
        default: return false
        }
    }
}

#Preview {
    AIWizardView()
        .withDependencies(.preview)
}

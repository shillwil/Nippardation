//
//  AIWizardView.swift
//  Nippardation
//
//  Multi-step wizard for AI-powered program generation
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
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.md)

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

                // Navigation buttons
                HStack(spacing: AppSpacing.md) {
                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            Text("Back")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    if currentStep < totalSteps - 1 {
                        Button {
                            withAnimation { currentStep += 1 }
                        } label: {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AIColors.accent)
                        .controlSize(.large)
                        .disabled(!isCurrentStepValid)
                    } else {
                        AIGradientButton(
                            "Generate Program",
                            isDisabled: !viewModel.canGenerate
                        ) {
                            viewModel.generate()
                        }
                        .controlSize(.large)
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("AI Program Generator")
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
            .alert("Generation Failed", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                if viewModel.errorIsRetryable {
                    Button("Try Again") {
                        viewModel.clearError()
                        viewModel.generate()
                    }
                    Button("Cancel", role: .cancel) { viewModel.clearError() }
                } else {
                    Button("OK") { viewModel.clearError() }
                }
            } message: {
                Text(viewModel.error ?? "An unknown error occurred")
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

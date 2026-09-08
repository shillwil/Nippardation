//
//  ProgramWizardView.swift
//  Nippardation
//
//  Three-step wizard for building a new plan. Presented modally inside the presenter's NavigationStack.
//

import SwiftUI

struct ProgramWizardView: View {
    @StateObject private var viewModel = ProgramEditorViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            StepIndicator(totalSteps: totalSteps, currentStep: currentStep)
                .padding(.top, VoidSpace.s3)
                .padding(.bottom, VoidSpace.s4)

            Group {
                switch currentStep {
                case 0:
                    ProgramWizardStep1(viewModel: viewModel)
                case 1:
                    ProgramWizardStep2(viewModel: viewModel)
                case 2:
                    ProgramWizardStep3(viewModel: viewModel)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            WizardFooter(showBack: currentStep > 0, onBack: { currentStep -= 1 }) {
                VoidCTAButton(
                    title: currentStep < totalSteps - 1 ? "Continue" : "Create plan",
                    isEnabled: isCurrentStepValid,
                    isLoading: viewModel.isSaving
                ) {
                    if currentStep < totalSteps - 1 {
                        currentStep += 1
                    } else {
                        viewModel.save()
                    }
                }
            }
        }
        .voidScreen()
        .navigationTitle("New plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear {
            viewModel.loadTemplates()
        }
        .onChange(of: viewModel.savedProgram) { _, newValue in
            if newValue != nil { dismiss() }
        }
        .disabled(viewModel.isSaving)
        .overlay {
            if viewModel.isSaving {
                WizardBusyOverlay(eyebrow: "Saving")
            }
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

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0: return viewModel.isStep1Valid
        case 1: return viewModel.isStep2Valid
        case 2: return viewModel.isValid
        default: return false
        }
    }
}

#Preview {
    NavigationStack {
        ProgramWizardView()
    }
    .withDependencies(.preview)
}

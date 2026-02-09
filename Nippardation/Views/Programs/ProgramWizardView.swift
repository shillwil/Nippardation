//
//  ProgramWizardView.swift
//  Nippardation
//
//  Multi-step wizard for creating new programs
//

import SwiftUI

struct ProgramWizardView: View {
    @StateObject private var viewModel = ProgramEditorViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            StepIndicator(totalSteps: totalSteps, currentStep: currentStep)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.md)

            // Step content
            Group {
                switch currentStep {
                case 0:
                    ProgramWizardStep1(viewModel: viewModel)
                case 1:
                    // Step 2: Schedule builder (PR9)
                    Text("Step 2: Schedule — Coming in PR9")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case 2:
                    // Step 3: Review (PR9)
                    Text("Step 3: Review — Coming in PR9")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

                Button {
                    if currentStep < totalSteps - 1 {
                        withAnimation { currentStep += 1 }
                    } else {
                        viewModel.save()
                    }
                } label: {
                    Text(currentStep < totalSteps - 1 ? "Continue" : "Create Program")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isCurrentStepValid)
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("New Program")
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
                ProgressView("Creating...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.error ?? "An unknown error occurred")
        }
    }

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0: return viewModel.isStep1Valid
        case 1: return true // Step 2 validation in PR9
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

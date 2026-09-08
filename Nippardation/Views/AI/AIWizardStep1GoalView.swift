//
//  AIWizardStep1GoalView.swift
//  Nippardation
//
//  Step 1: training goal and split preference.
//

import SwiftUI

struct AIWizardStep1GoalView: View {
    @ObservedObject var viewModel: AIWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoidSpace.s6) {
                AISectionHeader("Your goal", subtitle: "Pick a training focus.")
                    .padding(.horizontal, VoidSpace.s1)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    ForEach(AITrainingGoal.allCases) { goal in
                        goalCard(goal)
                    }
                }

                VStack(alignment: .leading, spacing: VoidSpace.s2) {
                    WizardSectionLabel(title: "Preferred split")
                    WizardHelperText(text: "Pick a split or describe your own.")

                    FlowLayout(spacing: VoidSpace.s2) {
                        ForEach(AISplitSuggestion.allCases) { suggestion in
                            WizardChip(
                                title: suggestion.rawValue,
                                isSelected: viewModel.selectedSplitSuggestion == suggestion
                            ) {
                                viewModel.selectSplitSuggestion(suggestion)
                            }
                        }
                    }
                    .padding(.top, VoidSpace.s1)

                    VoidTextField(placeholder: "Or type your own, e.g. Arnold split", text: $viewModel.inspirationSource)
                        .onChange(of: viewModel.inspirationSource) { _, newValue in
                            // Clear the chip when the text no longer matches it.
                            if let selected = viewModel.selectedSplitSuggestion,
                               newValue != selected.rawValue {
                                viewModel.selectedSplitSuggestion = nil
                            }
                        }
                }
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.vertical, VoidSpace.s2)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Subviews

    private func goalCard(_ goal: AITrainingGoal) -> some View {
        WizardOptionCard(isSelected: viewModel.selectedGoal == goal, action: {
            viewModel.selectedGoal = goal
        }) {
            VStack(alignment: .leading, spacing: VoidSpace.s2) {
                Image(systemName: goal.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(VoidColor.text)
                    .frame(height: 26)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayName)
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                    Text(goal.subtitle)
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
        .accessibilityLabel("\(goal.displayName), \(goal.subtitle)")
    }
}

// MARK: - Flow Layout

/// Simple flow layout for wrapping chips horizontally
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

#Preview {
    NavigationStack {
        AIWizardStep1GoalView(viewModel: AIWizardViewModel())
            .voidScreen()
    }
    .withDependencies(.preview)
}

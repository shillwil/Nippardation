//
//  AIWizardStep1GoalView.swift
//  Nippardation
//
//  Step 1: Training goal and split preference selection
//

import SwiftUI

struct AIWizardStep1GoalView: View {
    @ObservedObject var viewModel: AIWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                AISectionHeader("What's Your Goal?", subtitle: "Choose your training focus")

                // Goal selection grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppSpacing.sm) {
                    ForEach(AITrainingGoal.allCases) { goal in
                        goalCard(goal)
                    }
                }

                Divider()
                    .padding(.vertical, AppSpacing.xs)

                // Split preference
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Preferred Split")
                        .font(.headline)

                    Text("Choose a template or describe your ideal split")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Suggestion chips
                    FlowLayout(spacing: AppSpacing.xs) {
                        ForEach(AISplitSuggestion.allCases) { suggestion in
                            splitChip(suggestion)
                        }
                    }

                    TextField("Or type your own (e.g., \"Arnold Split\")", text: $viewModel.inspirationSource)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.inspirationSource) { _, newValue in
                            // Clear chip selection if user types custom text
                            if let selected = viewModel.selectedSplitSuggestion,
                               newValue != selected.rawValue {
                                viewModel.selectedSplitSuggestion = nil
                            }
                        }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Subviews

    private func goalCard(_ goal: AITrainingGoal) -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) {
                viewModel.selectedGoal = goal
            }
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(
                        viewModel.selectedGoal == goal
                            ? AnyShapeStyle(AIColors.gradient)
                            : AnyShapeStyle(Color.secondary)
                    )

                Text(goal.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(goal.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(
                viewModel.selectedGoal == goal
                    ? AIColors.subtleGradient
                    : LinearGradient(colors: [Color(.secondarySystemBackground)], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(
                        viewModel.selectedGoal == goal ? AIColors.accent.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func splitChip(_ suggestion: AISplitSuggestion) -> some View {
        Button {
            viewModel.selectSplitSuggestion(suggestion)
        } label: {
            Text(suggestion.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .foregroundColor(
                    viewModel.selectedSplitSuggestion == suggestion ? .white : .primary
                )
                .background(
                    viewModel.selectedSplitSuggestion == suggestion
                        ? AnyShapeStyle(AIColors.gradient)
                        : AnyShapeStyle(Color(.tertiarySystemBackground))
                )
                .cornerRadius(AppCornerRadius.small)
        }
        .buttonStyle(.plain)
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
    }
    .withDependencies(.preview)
}

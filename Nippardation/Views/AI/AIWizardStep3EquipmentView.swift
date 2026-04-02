//
//  AIWizardStep3EquipmentView.swift
//  Nippardation
//
//  Step 3: Equipment selection and experience level
//

import SwiftUI

struct AIWizardStep3EquipmentView: View {
    @ObservedObject var viewModel: AIWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                AISectionHeader("Your Setup", subtitle: "Select your experience level and available equipment")

                // Experience level
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Experience Level")
                        .font(.headline)

                    Picker("Experience", selection: $viewModel.experienceLevel) {
                        ForEach(AIExperienceLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Divider()
                    .padding(.vertical, AppSpacing.xs)

                // Equipment selection
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("Available Equipment")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.selectedEquipment.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppSpacing.sm) {
                        ForEach(AIEquipment.allCases) { equipment in
                            equipmentCard(equipment)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Subviews

    private func equipmentCard(_ equipment: AIEquipment) -> some View {
        let isSelected = viewModel.selectedEquipment.contains(equipment)

        return Button {
            withAnimation(.spring(duration: 0.2)) {
                if isSelected {
                    viewModel.selectedEquipment.remove(equipment)
                } else {
                    viewModel.selectedEquipment.insert(equipment)
                }
            }
        } label: {
            VStack(spacing: AppSpacing.xxs) {
                Image(systemName: equipment.icon)
                    .font(.title3)
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(AIColors.gradient)
                            : AnyShapeStyle(Color.secondary)
                    )

                Text(equipment.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.xxs)
            .background(
                isSelected
                    ? AIColors.subtleGradient
                    : LinearGradient(colors: [Color(.secondarySystemBackground)], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(AppCornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .stroke(isSelected ? AIColors.accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AIWizardStep3EquipmentView(viewModel: AIWizardViewModel())
    }
    .withDependencies(.preview)
}

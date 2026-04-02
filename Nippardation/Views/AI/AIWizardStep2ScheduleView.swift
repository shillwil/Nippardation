//
//  AIWizardStep2ScheduleView.swift
//  Nippardation
//
//  Step 2: Training schedule (days per week and session duration)
//

import SwiftUI

struct AIWizardStep2ScheduleView: View {
    @ObservedObject var viewModel: AIWizardViewModel

    private let durations = [30, 45, 60, 75, 90, 120]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                AISectionHeader("Your Schedule", subtitle: "How often and how long can you train?")

                // Days per week
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Days Per Week")
                        .font(.headline)

                    HStack(spacing: AppSpacing.xs) {
                        ForEach(1...7, id: \.self) { day in
                            dayCircle(day)
                        }
                    }

                    Text("\(viewModel.daysPerWeek) training day\(viewModel.daysPerWeek == 1 ? "" : "s") per week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .padding(.vertical, AppSpacing.xs)

                // Session duration
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Session Duration")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppSpacing.sm) {
                        ForEach(durations, id: \.self) { minutes in
                            durationCard(minutes)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    // MARK: - Subviews

    private func dayCircle(_ day: Int) -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) {
                viewModel.daysPerWeek = day
            }
        } label: {
            Text("\(day)")
                .font(.title3)
                .fontWeight(.semibold)
                .frame(width: 44, height: 44)
                .foregroundColor(viewModel.daysPerWeek == day ? .white : .primary)
                .background(
                    viewModel.daysPerWeek == day
                        ? AnyShapeStyle(AIColors.gradient)
                        : AnyShapeStyle(Color(.tertiarySystemBackground))
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func durationCard(_ minutes: Int) -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) {
                viewModel.sessionDurationMinutes = minutes
            }
        } label: {
            VStack(spacing: AppSpacing.xxs) {
                Text("\(minutes)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                viewModel.sessionDurationMinutes == minutes
                    ? AIColors.subtleGradient
                    : LinearGradient(colors: [Color(.secondarySystemBackground)], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(
                        viewModel.sessionDurationMinutes == minutes ? AIColors.accent.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AIWizardStep2ScheduleView(viewModel: AIWizardViewModel())
    }
    .withDependencies(.preview)
}

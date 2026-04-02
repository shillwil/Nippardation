//
//  NoProgramsModalView.swift
//  Nippardation
//
//  Modal shown when a user with no programs taps "Start Workout"
//

import SwiftUI

struct NoProgramsModalView: View {
    let templates: [Template]
    let onCreateManually: () -> Void
    let onGenerateWithAI: () -> Void
    let onBrowsePrograms: () -> Void
    let onSelectTemplate: (Template) -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, AppSpacing.sm)

            if templates.isEmpty {
                emptyState
            } else {
                templateListState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State (no templates, no programs)

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.appTheme.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 40))
                    .foregroundColor(.appTheme)
            }

            // Title & description
            VStack(spacing: AppSpacing.xs) {
                Text("Create a Program First")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("To start a workout, you need at least one program with workout templates. Create or generate one to get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            createProgramButtons

            Spacer()
        }
    }

    // MARK: - Template List State (has templates, no programs)

    private var templateListState: some View {
        VStack(spacing: AppSpacing.sm) {
            VStack(spacing: AppSpacing.xxs) {
                Text("No Program Yet")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Start a workout from a saved template, or create a program to organize your training.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.md)
            }

            ScrollView {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(templates) { template in
                        Button {
                            onSelectTemplate(template)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .lineLimit(1)

                                    Text("\(template.exerciseCount) exercises")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "play.circle.fill")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                            }
                            .padding(AppSpacing.sm)
                            .cardStyle()
                            .contentShape(Rectangle())
                        }
                        .tint(Color.appTheme)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }

            createProgramButtons
                .padding(.bottom, AppSpacing.sm)
        }
    }

    // MARK: - Shared CTAs

    private var createProgramButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            AIGradientButton("Generate with AI") {
                onGenerateWithAI()
            }
            .padding(.horizontal, AppSpacing.xl)

            Button(action: onCreateManually) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Manually")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, AppSpacing.xl)

            Button(action: onBrowsePrograms) {
                Text("Browse Programs")
                    .font(.subheadline)
                    .foregroundColor(.appTheme)
            }
        }
    }
}

#Preview("No Templates") {
    NoProgramsModalView(
        templates: [],
        onCreateManually: {},
        onGenerateWithAI: {},
        onBrowsePrograms: {},
        onSelectTemplate: { _ in }
    )
}

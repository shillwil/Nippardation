//
//  TemplateSelectorSheet.swift
//  Nippardation
//
//  Workout picker for the plan wizard.
//

import SwiftUI

struct TemplateSelectorSheet: View {
    let templates: [Template]
    let isLoading: Bool
    let onSelect: (Template) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: VoidSpace.s3) {
                        ProgressView().tint(VoidColor.plasma)
                        Text("Loading workouts")
                            .font(VoidFont.caption)
                            .foregroundStyle(VoidColor.text2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if templates.isEmpty {
                    VStack(spacing: VoidSpace.s4) {
                        VoidPlaceholder(eyebrow: "No workouts yet", caption: "Create a workout to use in your plan.")
                        VoidListPanel {
                            createWorkoutLink
                        }
                    }
                    .padding(.top, VoidSpace.s6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            VoidListPanel {
                                createWorkoutLink
                            }

                            VoidSectionRow(title: "Your workouts", trailing: VoidFormat.pad2(templates.count))
                                .padding(.top, VoidSpace.s3)

                            VoidListPanel {
                                ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                                    workoutRow(template)
                                    if index < templates.count - 1 {
                                        VoidHairline()
                                    }
                                }
                            }
                        }
                        .padding(.vertical, VoidSpace.s2)
                    }
                }
            }
            .voidScreen()
            .navigationTitle("Choose workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Rows

    private func workoutRow(_ template: Template) -> some View {
        Button {
            onSelect(template)
            dismiss()
        } label: {
            HStack(spacing: VoidSpace.s3) {
                WizardGlyphSquare(icon: VoidIcon.workoutGlyph(for: template.name))

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                    Text("\(template.exerciseCount) exercises · \(template.totalWorkingSets) sets")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                }

                Spacer(minLength: VoidSpace.s2)

                VoidChevron()
            }
            .frame(height: VoidSize.listRow)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidRowButtonStyle())
        .accessibilityElement(children: .combine)
    }

    private var createWorkoutLink: some View {
        NavigationLink {
            TemplateEditorView(onSave: { template in
                onSelect(template)
                dismiss()
            })
        } label: {
            HStack(spacing: VoidSpace.s3) {
                WizardGlyphSquare(icon: .plus)

                Text("Create new workout")
                    .font(VoidFont.bodyStrong)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(1)

                Spacer(minLength: VoidSpace.s2)

                VoidChevron()
            }
            .frame(height: VoidSize.listRow)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidRowButtonStyle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TemplateSelectorSheet(
        templates: MockTemplateRepository.sampleTemplates,
        isLoading: false,
        onSelect: { _ in }
    )
    .withDependencies(.preview)
}

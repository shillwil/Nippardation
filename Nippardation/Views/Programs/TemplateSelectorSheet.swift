//
//  TemplateSelectorSheet.swift
//  Nippardation
//
//  Workout picker for the plan wizard and the plan editor: a native list of the user's workouts,
//  plus a link that builds a new one.
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
                    ProgressView {
                        Text("Loading workouts")
                            .font(VoidFont.caption)
                            .foregroundStyle(VoidColor.text2)
                    }
                    .tint(VoidColor.plasma)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if templates.isEmpty {
                    ContentUnavailableView {
                        Label("No workouts yet", systemImage: VoidIcon.barbell.systemName)
                    } description: {
                        Text("Create a workout to use in your plan.")
                    } actions: {
                        NavigationLink {
                            newWorkoutEditor
                        } label: {
                            Text("Create new workout")
                                .foregroundStyle(VoidColor.onPlasma)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(VoidColor.plasma)
                    }
                } else {
                    List {
                        Section {
                            createWorkoutLink
                        }

                        Section {
                            ForEach(templates) { template in
                                workoutRow(template)
                            }
                        } header: {
                            Text("Your workouts")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .voidScreen()
            .navigationTitle("Choose workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Rows

    /// Picks the workout and closes the sheet, so the row carries no disclosure chevron.
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
            }
        }
        .listRowBackground(VoidColor.panel)
        .listRowSeparatorTint(VoidColor.hairline)
    }

    /// Pushes the workout editor; the list draws the disclosure chevron.
    private var createWorkoutLink: some View {
        NavigationLink {
            newWorkoutEditor
        } label: {
            HStack(spacing: VoidSpace.s3) {
                WizardGlyphSquare(icon: .plus)

                Text("Create new workout")
                    .font(VoidFont.bodyStrong)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(1)
            }
        }
        .listRowBackground(VoidColor.panel)
    }

    /// A saved new workout is picked straight away and the sheet closes.
    private var newWorkoutEditor: some View {
        TemplateEditorView(onSave: { template in
            onSelect(template)
            dismiss()
        })
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

#Preview("No workouts") {
    TemplateSelectorSheet(
        templates: [],
        isLoading: false,
        onSelect: { _ in }
    )
    .withDependencies(.preview)
}

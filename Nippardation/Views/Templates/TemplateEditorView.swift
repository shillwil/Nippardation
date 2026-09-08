//
//  TemplateEditorView.swift
//  Nippardation
//
//  Workout editor — name, split, exercises with sets / reps / rest. Pushed from the
//  library or a rotation row (Edit workout), or presented in a sheet (New workout).
//  Workouts that arrive from a list endpoint (exercise count only, no exercises) are
//  fetched in full before the editor opens so a save can never drop their exercises.
//

import SwiftUI

struct TemplateEditorView: View {

    private let existingTemplate: Template?
    private let onSave: ((Template) -> Void)?

    /// Wrapper to make exercise editing state identifiable for sheet presentation
    struct ExerciseEditContext: Identifiable {
        let id = UUID()
        let index: Int
        let exercise: TemplateEditorViewModel.EditableExercise
    }

    init(existingTemplate: Template? = nil, onSave: ((Template) -> Void)? = nil) {
        self.existingTemplate = existingTemplate
        self.onSave = onSave
    }

    var body: some View {
        if let template = existingTemplate, Self.needsFullRecord(template) {
            TemplateEditorLoader(template: template, onSave: onSave)
        } else {
            TemplateEditorContent(existingTemplate: existingTemplate, onSave: onSave)
        }
    }

    /// List endpoints can return a workout with `_knownExerciseCount` set and `exercises == []`.
    /// Editing that copy and saving would overwrite the server record with only the exercises
    /// added in the editor, so such a workout is fetched in full first.
    static func needsFullRecord(_ template: Template) -> Bool {
        template.exercises.isEmpty && template.exerciseCount > 0
    }
}

// MARK: - Full-record loader

/// Fetches the complete workout before handing it to the editor. Shows the library's
/// loading state, and a retry when the fetch fails or still comes back without exercises.
private struct TemplateEditorLoader: View {
    let template: Template
    let onSave: ((Template) -> Void)?

    @State private var fullTemplate: Template?
    @State private var loadError: String?
    @State private var attempt = 0

    private var templateRepository: any TemplateRepositoryProtocol { DependencyContainer.shared.templateRepository }

    var body: some View {
        if let fullTemplate {
            TemplateEditorContent(existingTemplate: fullTemplate, onSave: onSave)
        } else {
            VStack(spacing: VoidSpace.s4) {
                if let loadError {
                    VoidPlaceholder(eyebrow: "Couldn't load workout", caption: loadError)
                    VoidPillButton(title: "Retry") {
                        self.loadError = nil
                        attempt += 1
                    }
                } else {
                    ProgressView()
                        .tint(VoidColor.text2)
                    Text("Loading")
                        .voidEyebrowSm()
                }
            }
            .padding(.horizontal, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Edit workout")
            .navigationBarTitleDisplayMode(.inline)
            .voidScreen()
            .task(id: attempt) {
                await load()
            }
        }
    }

    private func load() async {
        guard !template.serverId.isEmpty else {
            loadError = "This workout has not synced yet."
            return
        }
        do {
            let fetched = try await templateRepository.fetchTemplate(serverId: template.serverId, forceRefresh: false)
            // The list said this workout has exercises; refuse to open an editor without them.
            if fetched.exercises.isEmpty {
                loadError = "The exercises for this workout could not be loaded."
            } else {
                fullTemplate = fetched
            }
        } catch let error as RepositoryError {
            loadError = error.errorDescription ?? "The workout could not be loaded."
        } catch {
            loadError = "The workout could not be loaded."
        }
    }
}

// MARK: - Editor

private struct TemplateEditorContent: View {

    @StateObject private var viewModel: TemplateEditorViewModel
    @StateObject private var shareViewModel = ShareViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showExercisePicker = false
    @State private var editingExercise: TemplateEditorView.ExerciseEditContext?
    @State private var showShareSheet = false
    @State private var isReordering = false

    /// Optional callback fired with the newly saved template
    private var onSave: ((Template) -> Void)?

    init(existingTemplate: Template? = nil, onSave: ((Template) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: TemplateEditorViewModel(existingTemplate: existingTemplate))
        self.onSave = onSave
    }

    var body: some View {
        ScrollView {
            VStack(spacing: VoidSpace.s3) {
                detailsPanel

                summaryRow

                MuscleAnalysisChart(distribution: viewModel.muscleGroupDistribution)
                    .padding(.horizontal, VoidSpace.insetCard)

                exercisesSection

                VoidCTAButton(title: "Add exercises") {
                    showExercisePicker = true
                }
                .padding(.horizontal, VoidSpace.insetCard)
                .padding(.top, VoidSpace.s1)
            }
            .padding(.top, VoidSpace.s2)
            .padding(.bottom, VoidSpace.s6)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(viewModel.isEditing ? "Edit workout" : "New workout")
        .navigationBarTitleDisplayMode(.inline)
        .voidScreen()
        .toolbar {
            if !viewModel.isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.isEditing {
                    shareButton
                }
                Button("Save") {
                    viewModel.save()
                }
                .fontWeight(.semibold)
                .disabled(!viewModel.isValid || viewModel.isSaving)
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            exercisePickerSheet
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareViewModel.shareURL {
                ShareActivityView(activityItems: [
                    PlanShareItemSource(url: url, title: viewModel.name, subtitle: shareSubtitle)
                ])
            }
        }
        .onChange(of: shareViewModel.shareURL) { _, url in
            if url != nil {
                showShareSheet = true
            }
        }
        .alert("Sharing error", isPresented: .init(
            get: { shareViewModel.error != nil },
            set: { if !$0 { shareViewModel.clearError() } }
        )) {
            Button("OK") { shareViewModel.clearError() }
        } message: {
            Text(shareViewModel.error ?? "")
        }
        .sheet(item: $editingExercise) { context in
            ExerciseConfigSheet(
                exercise: context.exercise,
                onSave: { warmup, working, reps, rest, notes in
                    viewModel.updateExercise(
                        at: context.index,
                        warmupSets: warmup,
                        workingSets: working,
                        targetReps: reps,
                        restSeconds: rest,
                        notes: notes
                    )
                },
                onDelete: {
                    viewModel.removeExercise(at: context.index)
                }
            )
        }
        .onChange(of: viewModel.savedTemplate) { _, newValue in
            if let template = newValue {
                onSave?(template)
                dismiss()
            }
        }
        .onChange(of: viewModel.exercises.count) { _, count in
            if count < 2 {
                isReordering = false
            }
        }
        .disabled(viewModel.isSaving)
        .overlay {
            if viewModel.isSaving {
                HStack(spacing: VoidSpace.s3) {
                    ProgressView()
                        .tint(VoidColor.text2)
                    Text("Saving")
                        .voidEyebrowSm()
                }
                .padding(VoidSpace.s4)
                .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2)
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error ?? "An unknown error occurred")
        }
    }

    // MARK: - Toolbar

    private var shareButton: some View {
        Button {
            if let serverId = viewModel.existingServerId {
                shareViewModel.createShare(type: "template", itemId: serverId)
            }
        } label: {
            if shareViewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: VoidIcon.share.systemName)
            }
        }
        .disabled(shareViewModel.isLoading)
        .accessibilityLabel("Share workout")
    }

    /// "6 exercises · 18 sets" for the share preview card.
    private var shareSubtitle: String {
        let count = viewModel.exercises.count
        return "\(count) \(count == 1 ? "exercise" : "exercises")\(VoidFormat.dot)\(viewModel.totalWorkingSets) sets"
    }

    // MARK: - Sections

    private var detailsPanel: some View {
        VStack(spacing: VoidSpace.s2) {
            VoidTextField(placeholder: "Workout name", text: $viewModel.name, autocapitalization: .words)
            MultilineTextWell(placeholder: "Description (optional)", text: $viewModel.description)
        }
        .padding(14)
        .voidPanel()
        .padding(.horizontal, VoidSpace.insetCard)
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            statReadout(value: VoidFormat.pad2(viewModel.exercises.count), label: "Exercises")
            statReadout(value: VoidFormat.pad2(viewModel.totalWarmupSets), label: "Warmup")
            statReadout(value: VoidFormat.pad2(viewModel.totalWorkingSets), label: "Working")
        }
        .padding(.horizontal, VoidSpace.insetCard)
    }

    private func statReadout(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: VoidSpace.s1) {
            Text(value)
                .voidNumber()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .voidEyebrowSm()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .voidPanel()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var exercisesSection: some View {
        VStack(spacing: VoidSpace.s2) {
            HStack {
                Text("Exercises\(VoidFormat.dot)\(VoidFormat.pad2(viewModel.exercises.count))")
                    .voidEyebrowSm()
                Spacer()
                if viewModel.exercises.count > 1 {
                    Button {
                        isReordering.toggle()
                    } label: {
                        Text(isReordering ? "Done" : "Reorder")
                            .font(VoidFont.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(VoidColor.text)
                            .frame(minWidth: VoidSize.hitMin, minHeight: VoidSize.hitMin)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(VoidPlainButtonStyle())
                }
            }
            .padding(.horizontal, VoidSpace.insetText)
            .padding(.top, VoidSpace.s3)

            if viewModel.exercises.isEmpty {
                VoidListPanel {
                    VoidPlaceholder(eyebrow: "No exercises yet", caption: "Add exercises to build the workout.")
                }
            } else {
                VoidListPanel {
                    exerciseList
                }
            }
        }
    }

    /// Exercise rows in a `List` so the system reorder handles drive `moveExercises`.
    /// Scrolling is disabled and the height is fixed so it sits inside the outer ScrollView.
    private var exerciseList: some View {
        List {
            ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseEditorCard(
                    index: index,
                    exercise: exercise,
                    isLast: index == viewModel.exercises.count - 1,
                    onConfigure: {
                        editingExercise = TemplateEditorView.ExerciseEditContext(index: index, exercise: exercise)
                    },
                    onDelete: {
                        viewModel.removeExercise(at: index)
                    },
                    onMoveUp: moveUpAction(index),
                    onMoveDown: moveDownAction(index)
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onMove { source, destination in
                viewModel.moveExercises(from: source, to: destination)
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, VoidSize.listRow)
        .environment(\.editMode, .constant(isReordering ? .active : .inactive))
        .frame(height: CGFloat(viewModel.exercises.count) * VoidSize.listRow)
    }

    private func moveUpAction(_ index: Int) -> (() -> Void)? {
        guard index > 0 else { return nil }
        return { viewModel.moveExercises(from: IndexSet(integer: index), to: index - 1) }
    }

    private func moveDownAction(_ index: Int) -> (() -> Void)? {
        guard index < viewModel.exercises.count - 1 else { return nil }
        return { viewModel.moveExercises(from: IndexSet(integer: index), to: index + 2) }
    }

    // MARK: - Exercise Picker Sheet

    private var exercisePickerSheet: some View {
        ExercisePickerSheet(
            onCancel: {
                showExercisePicker = false
            },
            onConfirm: { selectedExercises in
                viewModel.addExercises(selectedExercises)
                showExercisePicker = false
            }
        )
    }
}

// MARK: - Multi-line well

/// Multi-line text well for descriptions and notes: the same panel-2 fill, radius 12 and
/// SF 15 as `VoidTextField`, but it grows from three to six lines and Return inserts a newline.
/// Foundation gap: `VoidTextField` is a fixed 44pt single-line well.
struct MultilineTextWell: View {
    let placeholder: String
    @Binding var text: String
    var lines: ClosedRange<Int> = 3...6
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(lines)
            .font(VoidFont.body)
            .foregroundStyle(VoidColor.text)
            .textInputAutocapitalization(autocapitalization)
            .padding(14)
            .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2, fill: VoidColor.panel2)
    }
}

// MARK: - Exercise Picker Sheet Helper

private struct ExercisePickerSheet: View {
    let onCancel: () -> Void
    let onConfirm: ([ExerciseLibraryItem]) -> Void

    @StateObject private var browserViewModel = ExerciseBrowserViewModel(
        isPickerMode: true,
        maxSelections: nil
    )

    var body: some View {
        NavigationStack {
            ExerciseBrowserContent(
                viewModel: browserViewModel,
                onConfirmSelection: { selected in
                    onConfirm(selected)
                }
            )
            .navigationTitle("Add exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("New workout") {
    NavigationStack {
        TemplateEditorView()
    }
    .withDependencies(.preview)
}

#Preview("Edit workout") {
    NavigationStack {
        TemplateEditorView(existingTemplate: MockTemplateRepository.sampleTemplates[0])
    }
    .withDependencies(.preview)
}

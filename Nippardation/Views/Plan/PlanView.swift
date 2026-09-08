//
//  PlanView.swift
//  Nippardation
//
//  Plan tab (HANDOFF screen 2): the active plan's rotation — one row per workout day
//  (done / up next / later), the ··· menu, and the Other plans / Edit plan pills.
//  Loading → rotation → or, with no active plan, the Plans hub in place.
//

import SwiftUI

struct PlanView: View {

    @StateObject private var viewModel: PlanViewModel
    @StateObject private var shareViewModel = ShareViewModel()
    @EnvironmentObject private var navigation: AppNavigation

    @State private var route: Route?
    @State private var showEditor = false
    @State private var showShareSheet = false

    init() {
        _viewModel = StateObject(wrappedValue: PlanViewModel())
    }

    /// Preview / test entry point with a prepared view model.
    init(viewModel: PlanViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private enum Route: Hashable {
        case hub
        case library
        case account
        case workout(Template)
    }

    // MARK: - Body

    var body: some View {
        content
            .voidRootScreen()
            .navigationDestination(item: $route) { route in
                destination(route)
            }
            .sheet(isPresented: $showEditor, onDismiss: { viewModel.load() }) {
                editorSheet
            }
            .sheet(isPresented: $showShareSheet) {
                shareSheet
            }
            .sheet(isPresented: $viewModel.showTemplateDeleteSheet) {
                deleteSheet
            }
            .alert("Restart from day 1", isPresented: $viewModel.showRestartAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Restart") { viewModel.restart() }
            } message: {
                Text("The plan goes back to day 1. Your workout history is not changed.")
            }
            .alert("Delete plan", isPresented: $viewModel.showSimpleDeleteAlert) {
                Button("Cancel", role: .cancel) { viewModel.clearDeleteState() }
                Button("Delete", role: .destructive) { viewModel.deleteProgram() }
            } message: {
                Text("This removes the plan. Your workout history is not changed.")
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error ?? "")
            }
            .alert("Sharing error", isPresented: Binding(
                get: { shareViewModel.error != nil },
                set: { if !$0 { shareViewModel.clearError() } }
            )) {
                Button("OK") { shareViewModel.clearError() }
            } message: {
                Text(shareViewModel.error ?? "")
            }
            .onChange(of: shareViewModel.shareURL) { _, url in
                if url != nil { showShareSheet = true }
            }
            .onChange(of: viewModel.planMutation) { _, _ in
                navigation.planDidChange()
            }
            .onChange(of: navigation.planRevision) { _, _ in
                viewModel.load()
            }
            .onAppear {
                viewModel.load()
            }
            .overlay {
                busyOverlay
            }
    }

    @ViewBuilder
    private var content: some View {
        if let program = viewModel.program {
            rotation(program)
        } else if viewModel.hasLoaded {
            PlansHubView()
        } else {
            loadingPlaceholder
        }
    }

    // MARK: - Rotation

    private func rotation(_ program: Program) -> some View {
        VStack(spacing: 0) {
            VoidEyebrowRow(program.name) {
                HStack(spacing: VoidSpace.s3) {
                    if let week = viewModel.weekEyebrow {
                        Text(week).voidEyebrow()
                    }
                    planMenu(program)
                }
            }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, row in
                        Button {
                            open(row)
                        } label: {
                            PlanRotationRow(row: row, showsChevron: row.template != nil)
                        }
                        .buttonStyle(VoidRowButtonStyle())
                        // A row whose workout could not be resolved (offline, not cached) has nothing to open.
                        .disabled(row.template == nil)
                        .accessibilityHint(row.template == nil ? "" : "Opens the workout")

                        if index < viewModel.rows.count - 1 {
                            VoidHairline()
                        }
                    }
                }
                .padding(.top, VoidSpace.s5)
                .padding(.bottom, VoidSpace.s4)
            }
            .scrollBounceBehavior(.basedOnSize)

            VoidPillPair(
                leading: "Other plans",
                trailing: "Edit plan",
                onLeading: { route = .hub },
                onTrailing: { showEditor = true }
            )
            .padding(.top, VoidSpace.s3)
            .padding(.bottom, VoidSpace.pillsBottom)
        }
    }

    private func planMenu(_ program: Program) -> some View {
        VoidControlMenu(icon: .more, accessibilityLabel: "Plan options") {
            Button {
                route = .hub
            } label: {
                Label("Switch plan", systemImage: VoidIcon.swap.systemName)
            }
            Button {
                viewModel.showRestartAlert = true
            } label: {
                Label("Restart from day 1", systemImage: VoidIcon.restart.systemName)
            }
            Button {
                viewModel.pause()
            } label: {
                Label("Pause plan", systemImage: VoidIcon.pause.systemName)
            }
            Button {
                shareViewModel.createShare(type: "program", itemId: program.serverId)
            } label: {
                Label("Share plan", systemImage: VoidIcon.share.systemName)
            }
            Divider()
            Button {
                route = .library
            } label: {
                Label("Workout library", systemImage: VoidIcon.library.systemName)
            }
            Button {
                route = .account
            } label: {
                Label("Account", systemImage: VoidIcon.person.systemName)
            }
            Divider()
            Button(role: .destructive) {
                viewModel.prepareDelete()
            } label: {
                Label("Delete plan", systemImage: VoidIcon.trash.systemName)
            }
        }
        .menuOrder(.fixed)
        .disabled(viewModel.isBusy)
    }

    private func open(_ row: RotationRow) {
        guard let template = row.template else { return }
        route = .workout(template)
    }

    // MARK: - Loading

    private var loadingPlaceholder: some View {
        VStack(spacing: 0) {
            VoidEyebrowRow("Plan")
            Spacer()
            ProgressView()
                .tint(VoidColor.text2)
            Spacer()
        }
    }

    @ViewBuilder
    private var busyOverlay: some View {
        if viewModel.isBusy || viewModel.isFetchingDeleteDetail || shareViewModel.isLoading {
            ZStack {
                VoidColor.hull.opacity(0.6).ignoresSafeArea()
                ProgressView()
                    .tint(VoidColor.text)
                    .padding(VoidSpace.s6)
                    .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline2)
            }
            .accessibilityLabel("Working")
        }
    }

    // MARK: - Destinations & sheets

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .hub:
            PlansHubView(isRoot: false)
        case .library:
            TemplateListView()
        case .account:
            AccountView()
        case .workout(let template):
            TemplateEditorView(existingTemplate: template, onSave: { saved in
                viewModel.handleTemplateSaved(saved)
            })
        }
    }

    @ViewBuilder
    private var editorSheet: some View {
        if let program = viewModel.program {
            NavigationStack {
                ProgramEditorView(existingProgram: program, onSaved: { _ in
                    navigation.planDidChange()
                })
            }
        }
    }

    @ViewBuilder
    private var shareSheet: some View {
        if let url = shareViewModel.shareURL, let program = viewModel.program {
            ShareActivityView(activityItems: [
                PlanShareItemSource(
                    url: url,
                    title: program.name,
                    subtitle: PlanShareItemSource.subtitle(for: program)
                )
            ])
        }
    }

    @ViewBuilder
    private var deleteSheet: some View {
        if let detail = viewModel.programToDeleteDetail {
            ProgramDeleteConfirmationView(
                program: detail,
                isDeletingProgram: viewModel.isDeletingProgram,
                onConfirmDelete: { keepIds in
                    viewModel.deleteProgramWithTemplates(keepTemplateIds: keepIds)
                    // The sheet closes when the view model clears the delete state after the deletion completes.
                },
                onCancel: {
                    viewModel.clearDeleteState()
                }
            )
        }
    }
}

// MARK: - Previews

private extension PlanViewModel {
    /// The sample PPL plan with one workout done this week, one up next, the rest later.
    static var previewActive: PlanViewModel {
        let program = MockProgramRepository.samplePrograms[0]
        let templates = MockTemplateRepository.sampleTemplates
        let done = TrackedWorkout(date: Date(), workoutTemplate: "Push Day", trackedExercises: [], isCompleted: true)
        return .preview(program: program, templates: templates, completedWorkouts: [done])
    }

    /// The sample 8-week plan, nothing done yet.
    static var previewFixedLength: PlanViewModel {
        var program = MockProgramRepository.samplePrograms[1]
        program.isActive = true
        program.currentDayIndex = 2
        program.timesCompleted = 2
        return .preview(program: program, templates: MockTemplateRepository.sampleTemplates)
    }
}

#Preview("Active plan") {
    NavigationStack {
        PlanView(viewModel: .previewActive)
    }
    .environmentObject(AppNavigation())
    .environmentObject(AuthManager.shared)
    .environmentObject(DeepLinkRouter.shared)
    .withDependencies(.preview)
}

#Preview("Fixed length plan") {
    NavigationStack {
        PlanView(viewModel: .previewFixedLength)
    }
    .environmentObject(AppNavigation())
    .environmentObject(AuthManager.shared)
    .environmentObject(DeepLinkRouter.shared)
    .withDependencies(.preview)
}

#Preview("No plan") {
    NavigationStack {
        PlanView(viewModel: .preview(program: nil))
    }
    .environmentObject(AppNavigation())
    .environmentObject(AuthManager.shared)
    .environmentObject(DeepLinkRouter.shared)
    .withDependencies(.preview)
}

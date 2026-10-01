//
//  PlanView.swift
//  Nippardation
//
//  Plan tab (HANDOFF screen 2): the active plan's rotation — one list row per workout day
//  (done / skipped / up next / later) under the plan's name as the large title, the plan options
//  menu in the toolbar, and the Other plans / Edit plan pills.
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

    /// Screens pushed from the plan options menu and the Other plans pill.
    /// The rotation rows push their workout through their own `NavigationLink`.
    private enum Route: Hashable {
        case hub
        case library
        case account
    }

    // MARK: - Body

    var body: some View {
        content
            .voidScreen()
            .navigationDestination(item: $route) { route in
                destination(route)
            }
            .sheet(isPresented: $showEditor, onDismiss: { viewModel.load() }) {
                editorSheet
            }
            .sheet(isPresented: $showShareSheet) {
                shareSheet
                    .presentationDetents([.medium, .large])
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
    }

    /// The title and toolbar live on each branch: with no active plan the Plans hub sets its own.
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

    /// A menu action (restart / pause / delete) or a share link is in flight. The menu's place
    /// in the toolbar shows a spinner meanwhile, and the rotation and pills wait.
    private var isWorking: Bool {
        viewModel.isBusy || viewModel.isFetchingDeleteDetail || shareViewModel.isLoading
    }

    // MARK: - Rotation

    private func rotation(_ program: Program) -> some View {
        List {
            if let week = weekTitle {
                Section {
                    rotationRows
                } header: {
                    Text(week)
                }
            } else {
                Section {
                    rotationRows
                }
            }
        }
        .listStyle(.plain)
        .scrollBounceBehavior(.basedOnSize)
        .disabled(isWorking)
        .planBottomBar {
            VoidPillPair(
                leading: "Other plans",
                trailing: "Edit plan",
                onLeading: { route = .hub },
                onTrailing: { showEditor = true }
            )
            .padding(.vertical, VoidSpace.s3)
            .disabled(isWorking)
        }
        .wrappingNavigationTitle(program.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isWorking {
                    ProgressView()
                        .accessibilityLabel("Working")
                } else {
                    planMenu(program)
                }
            }
        }
    }

    /// Full-width rows on the hull, as in the Void spec: the row draws its own insets and the
    /// up-next mark at its leading edge; the list draws the separators and the chevrons.
    private var rotationRows: some View {
        ForEach(viewModel.rows) { row in
            rotationRow(row)
                // Flush leading edge for the up-next mark; the chevron keeps the card inset.
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: VoidSpace.insetCard))
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(VoidColor.hairline)
        }
    }

    @ViewBuilder
    private func rotationRow(_ row: RotationRow) -> some View {
        if let template = row.template {
            NavigationLink {
                TemplateEditorView(existingTemplate: template, onSave: { saved in
                    viewModel.handleTemplateSaved(saved)
                })
            } label: {
                PlanRotationRow(row: row)
            }
            .accessibilityHint("Opens the workout")
        } else {
            // A row whose workout could not be resolved (offline, not cached) has nothing to open.
            PlanRotationRow(row: row)
        }
    }

    /// "Week 3 of 8", or "Week 3" for an ongoing plan.
    private var weekTitle: String? {
        guard let current = viewModel.stats.planCurrentWeek else { return nil }
        if let total = viewModel.stats.planTotalWeeks {
            return "Week \(current) of \(total)"
        }
        return "Week \(current)"
    }

    private func planMenu(_ program: Program) -> some View {
        Menu {
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
        } label: {
            Label("Plan options", systemImage: Self.moreSymbol)
        }
        .menuOrder(.fixed)
    }

    /// iOS 26 draws the glass circle around a bar glyph itself; earlier versions use the circled glyph.
    private static var moreSymbol: String {
        if #available(iOS 26.0, *) {
            return VoidIcon.more.systemName
        }
        return "ellipsis.circle"
    }

    // MARK: - Loading

    private var loadingPlaceholder: some View {
        ProgressView()
            .tint(VoidColor.text2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.large)
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

// MARK: - Bottom bar

extension View {
    /// Pins a Plan screen's bottom actions (the Other plans / Edit plan pills, the Activate button)
    /// above the tab bar. On iOS 26 it is a safe-area bar, so the scroll edge effect runs under it;
    /// earlier versions put it on the hull so rows don't show through between the buttons.
    @ViewBuilder
    func planBottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .bottom, spacing: 0) {
                bar()
            }
        } else {
            safeAreaInset(edge: .bottom, spacing: 0) {
                bar()
                    .background(VoidColor.hull)
            }
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

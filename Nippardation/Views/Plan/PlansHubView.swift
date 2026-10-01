//
//  PlansHubView.swift
//  Nippardation
//
//  The Plans hub (HANDOFF screen 4): the one place to get a plan — generate it, receive it,
//  restore it, later browse the community's. Shown as the Plan tab root when there is no
//  active plan (`isRoot`), and pushed from Plan → Other plans / Switch plan.
//  A grouped list: the create buttons, Sent to you, Your plans, Community.
//

import SwiftUI

struct PlansHubView: View {
    /// Root of the Plan tab (no active plan) vs pushed from Plan; decides where the active plan's row goes.
    var isRoot: Bool = true

    @StateObject private var viewModel: PlansHubViewModel
    @EnvironmentObject private var navigation: AppNavigation
    @Environment(\.dismiss) private var dismiss

    @State private var showAccount = false
    @State private var showPaste = false
    @State private var showStarter = false
    @State private var showBuild = false
    @State private var showAI = false
    @State private var pendingLinkURL: URL?

    init(isRoot: Bool = true, viewModel: PlansHubViewModel? = nil) {
        self.isRoot = isRoot
        _viewModel = StateObject(wrappedValue: viewModel ?? PlansHubViewModel())
    }

    // MARK: - Body

    var body: some View {
        List {
            createSection

            if !viewModel.receivedPlans.isEmpty {
                sentSection
            }

            yourPlansSection

            communitySection
        }
        .listStyle(.insetGrouped)
        .voidScreen()
        .navigationTitle("Plans")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Paste a link", systemImage: VoidIcon.link.systemName) {
                    showPaste = true
                }
                Button("Account", systemImage: VoidIcon.person.systemName) {
                    showAccount = true
                }
            }
        }
        .navigationDestination(isPresented: $showAccount) {
            AccountView()
        }
        .onAppear { viewModel.load() }
        .onChange(of: navigation.planRevision) { _, _ in viewModel.load() }
        .onChange(of: viewModel.mutationCount) { _, _ in navigation.planDidChange() }
        .sheet(isPresented: $showPaste, onDismiss: routePendingLink) {
            PasteLinkSheet { url in pendingLinkURL = url }
        }
        .sheet(isPresented: $showStarter, onDismiss: { viewModel.load() }) {
            StarterPlansSheet { _ in
                navigation.planDidChange()
                navigation.show(.today)
            }
            .environmentObject(navigation)
        }
        .sheet(isPresented: $showBuild, onDismiss: reloadAfterCreate) {
            // The wizard brings its own NavigationStack.
            ProgramWizardView()
                .environmentObject(navigation)
        }
        .fullScreenCover(isPresented: $showAI, onDismiss: reloadAfterCreate) {
            // With no plan running, the new plan becomes the active one and Today is where it starts.
            AIWizardView(activatesPlanOnSave: isRoot) {
                navigation.planDidChange()
                navigation.show(.today)
            }
            .environmentObject(navigation)
        }
        .alert("Delete plan", isPresented: Binding(
            get: { viewModel.programs.showSimpleDeleteAlert },
            set: { viewModel.programs.showSimpleDeleteAlert = $0 }
        )) {
            Button("Cancel", role: .cancel) { viewModel.programs.clearDeleteState() }
            Button("Delete", role: .destructive) {
                if let program = viewModel.programs.programToDelete {
                    viewModel.programs.deleteProgram(program)
                }
                viewModel.programs.clearDeleteState()
            }
        } message: {
            Text("This removes the plan. Your workout history is never changed.")
        }
        .sheet(isPresented: Binding(
            get: { viewModel.programs.showTemplateDeleteSheet },
            set: { viewModel.programs.showTemplateDeleteSheet = $0 }
        )) {
            if let detail = viewModel.programs.programToDeleteDetail {
                ProgramDeleteConfirmationView(
                    program: detail,
                    isDeletingProgram: viewModel.programs.isDeletingProgram,
                    onConfirmDelete: { keepIds in
                        viewModel.programs.deleteProgramWithTemplates(keepTemplateIds: keepIds)
                    },
                    onCancel: {
                        viewModel.programs.clearDeleteState()
                    }
                )
            }
        }
    }

    /// A native section header with an optional trailing note ("1 new", the plan count, "Coming soon").
    private func sectionHeader(_ title: String, trailing: String? = nil) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: VoidSpace.s2)
            if let trailing {
                Text(trailing)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Create

    /// Three buttons on the hull, in a row or stacked: the AI plan is the screen's one plasma action.
    private var createSection: some View {
        Section {
            // Side by side while all three titles fit; stacked at large text sizes instead of truncating.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { createButtons }
                VStack(spacing: 10) { createButtons }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var createButtons: some View {
        createButton("AI plan", icon: .sparkle, prominent: true) { showAI = true }
        createButton("Starter", icon: .list) { showStarter = true }
        createButton("Build", icon: .plus) { showBuild = true }
    }

    @ViewBuilder
    private func createButton(_ title: String, icon: VoidIcon, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        let button = Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon.systemName)
                    .font(.title2.weight(.medium))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(prominent ? VoidColor.onPlasma : VoidColor.text)
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonBorderShape(.roundedRectangle(radius: VoidRadius.tile))

        if prominent {
            button
                .buttonStyle(.borderedProminent)
                .tint(VoidColor.plasma)
        } else {
            button
                .buttonStyle(.bordered)
                .tint(VoidColor.text)
        }
    }

    // MARK: - Sent to you

    private var sentSection: some View {
        Section {
            ForEach(viewModel.receivedPlans) { plan in
                receivedRow(plan)
            }
        } header: {
            let unread = viewModel.unreadCount
            sectionHeader("Sent to you", trailing: unread > 0 ? "\(unread) new" : nil)
        }
    }

    /// Opens the Plan received sheet, so a button row without a chevron.
    private func receivedRow(_ plan: ReceivedPlan) -> some View {
        Button {
            DeepLinkRouter.shared.open(token: plan.token)
        } label: {
            HStack(spacing: 12) {
                VoidAvatar(text: VoidFormat.initials(plan.sharedByName))
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name)
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                    Text(plan.caption())
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if !plan.isRead {
                    PlasmaDot()
                }
            }
        }
        .listRowBackground(VoidColor.panel)
        .listRowSeparatorTint(VoidColor.hairline)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.removeReceived(plan)
            } label: {
                Label("Remove", systemImage: VoidIcon.trash.systemName)
            }
            .tint(.red) // the plasma tint would otherwise recolour it
        }
        .contextMenu {
            Button(role: .destructive) {
                viewModel.removeReceived(plan)
            } label: {
                Label("Remove", systemImage: VoidIcon.trash.systemName)
            }
        }
        .accessibilityValue(plan.isRead ? "" : "New")
    }

    // MARK: - Your plans

    private var yourPlansSection: some View {
        let rows = viewModel.planRows
        return Section {
            if rows.isEmpty {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(VoidColor.plasma)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, VoidSpace.s4)
                    } else {
                        VoidPlaceholder(
                            eyebrow: "No plans yet",
                            caption: "Generate one, pick a starter, build your own, or paste a link."
                        )
                    }
                }
                .listRowBackground(VoidColor.panel)
            } else {
                ForEach(rows) { row in
                    planRow(row)
                }
            }
        } header: {
            sectionHeader("Your plans", trailing: rows.isEmpty ? nil : "\(rows.count)")
        } footer: {
            if let error = viewModel.error, rows.isEmpty {
                Text(error)
            }
        }
    }

    /// Inactive plans push their preview (system chevron); the active plan's row goes back to its rotation.
    private func planRow(_ row: PlansHubViewModel.PlanRow) -> some View {
        Group {
            if row.isActive {
                Button {
                    goToActivePlan()
                } label: {
                    planRowLabel(row)
                }
            } else {
                NavigationLink {
                    PlanPreviewView(program: row.program)
                } label: {
                    planRowLabel(row)
                }
            }
        }
        .listRowBackground(planRowBackground(row))
        .listRowSeparatorTint(VoidColor.hairline)
        .swipeActions(edge: .trailing) {
            // A confirmation follows, so a red button rather than the destructive role,
            // which would animate the row away before the user confirms.
            Button {
                viewModel.prepareDelete(row.program)
            } label: {
                Label("Delete", systemImage: VoidIcon.trash.systemName)
            }
            .tint(.red)
            Button {
                viewModel.duplicate(row.program)
            } label: {
                Label("Duplicate", systemImage: VoidIcon.plus.systemName)
            }
            .tint(.gray)
        }
        .contextMenu {
            if !row.isActive {
                Button {
                    viewModel.activate(row.program)
                } label: {
                    Label("Activate", systemImage: VoidIcon.check.systemName)
                }
            }
            Button {
                viewModel.duplicate(row.program)
            } label: {
                Label("Duplicate", systemImage: VoidIcon.plus.systemName)
            }
            Divider()
            Button(role: .destructive) {
                viewModel.prepareDelete(row.program)
            } label: {
                Label("Delete", systemImage: VoidIcon.trash.systemName)
            }
        }
    }

    private func planRowLabel(_ row: PlansHubViewModel.PlanRow) -> some View {
        HStack(spacing: 12) {
            VoidAvatar(text: row.initials, plasma: row.isActive, dimmed: row.isPaused)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.program.name)
                    .font(VoidFont.bodyStrong)
                    .foregroundStyle(row.isPaused ? VoidColor.text3 : VoidColor.text)
                    .lineLimit(1)
                Text(row.caption)
                    .font(VoidFont.caption2)
                    .foregroundStyle(row.isPaused ? VoidColor.text3 : VoidColor.text2)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
        }
    }

    /// The panel fill, plus the up-next mark flush to the panel's leading edge on the active plan.
    private func planRowBackground(_ row: PlansHubViewModel.PlanRow) -> some View {
        ZStack(alignment: .leading) {
            VoidColor.panel
            if row.isActive {
                UpNextMark()
            }
        }
    }

    // MARK: - Community

    private var communitySection: some View {
        Section {
            HStack(spacing: 12) {
                VoidAvatar(text: "4D")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommended for 4 days a week")
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                    Text("Upper / Lower · coming soon")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
            }
            .opacity(0.45)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Community plans, coming soon")
            .listRowBackground(VoidColor.panel)
        } header: {
            sectionHeader("Community", trailing: "Coming soon")
        }
    }

    // MARK: - Actions

    private func goToActivePlan() {
        if isRoot {
            navigation.planDidChange()
            navigation.show(.plan)
        } else {
            dismiss()
        }
    }

    private func routePendingLink() {
        guard let url = pendingLinkURL else { return }
        pendingLinkURL = nil
        DeepLinkRouter.shared.handleURL(url)
    }

    private func reloadAfterCreate() {
        viewModel.load()
        navigation.planDidChange()
    }
}

// MARK: - Previews

#Preview("Received + plans") {
    let store = ReceivedPlansStore(
        defaults: UserDefaults(suiteName: "preview.plans.hub") ?? .standard,
        userIdProvider: { "preview" }
    )
    store.removeAll()
    store.save(ReceivedPlan(
        token: "mock_abc123",
        type: "program",
        name: "Marcus' Upper / Lower",
        sharedByName: "Marcus",
        dayCount: 4,
        estimatedMinutes: 60,
        durationWeeks: 8,
        receivedAt: Date(),
        isRead: false
    ))
    store.save(ReceivedPlan(
        token: "mock_def456",
        type: "template",
        name: "Dee's Push Day",
        sharedByName: "Dee",
        dayCount: 1,
        estimatedMinutes: 45,
        durationWeeks: nil,
        receivedAt: Date().addingTimeInterval(-86400 * 8),
        isRead: true
    ))
    let viewModel = PlansHubViewModel(
        programs: ProgramListViewModel(programRepository: MockProgramRepository()),
        received: store
    )
    return NavigationStack {
        PlansHubView(isRoot: true, viewModel: viewModel)
    }
    .environmentObject(AppNavigation())
    .environmentObject(AuthManager.shared)
    .withDependencies(.preview)
}

#Preview("Empty") {
    let store = ReceivedPlansStore(
        defaults: UserDefaults(suiteName: "preview.plans.hub.empty") ?? .standard,
        userIdProvider: { "preview" }
    )
    store.removeAll()
    let repository = MockProgramRepository()
    let viewModel = PlansHubViewModel(
        programs: ProgramListViewModel(programRepository: repository),
        received: store
    )
    return NavigationStack {
        PlansHubView(isRoot: false, viewModel: viewModel)
    }
    .environmentObject(AppNavigation())
    .environmentObject(AuthManager.shared)
    .withDependencies(.preview)
    .task {
        for program in MockProgramRepository.samplePrograms {
            try? await repository.deleteProgram(serverId: program.serverId)
        }
        viewModel.load()
    }
}

//
//  PlansHubView.swift
//  Nippardation
//
//  The Plans hub (HANDOFF screen 4): the one place to get a plan — generate it, receive it,
//  restore it, later browse the community's. Shown as the Plan tab root when there is no
//  active plan (`isRoot`), and pushed from Plan → Other plans / Switch plan.
//

import SwiftUI

struct PlansHubView: View {
    /// Root of the Plan tab (eyebrow row + hidden nav bar) vs pushed (inline eyebrow title).
    var isRoot: Bool = true

    @StateObject private var viewModel: PlansHubViewModel
    @EnvironmentObject private var navigation: AppNavigation
    @Environment(\.dismiss) private var dismiss

    @State private var route: PlansHubRoute?
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
        screen
            .navigationDestination(item: $route) { route in
                switch route {
                case .account:
                    AccountView()
                case .preview(let program):
                    PlanPreviewView(program: program)
                }
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
                NavigationStack {
                    ProgramWizardView()
                }
                .environmentObject(navigation)
            }
            .fullScreenCover(isPresented: $showAI, onDismiss: reloadAfterCreate) {
                AIWizardView()
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

    @ViewBuilder
    private var screen: some View {
        if isRoot {
            content
                .voidRootScreen()
        } else {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Plans").voidEyebrow()
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        controls
                    }
                }
                .voidScreen()
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isRoot {
                    VoidEyebrowRow("Plans") { controls }
                }

                createRow
                    .padding(.top, 14)

                if !viewModel.receivedPlans.isEmpty {
                    sentSection
                }

                yourPlansSection

                communitySection
            }
            .padding(.bottom, VoidSpace.pillsBottom)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Eyebrow controls

    private var controls: some View {
        HStack(spacing: 12) {
            VoidControlButton(icon: .link, accessibilityLabel: "Paste a link") {
                showPaste = true
            }
            VoidControlButton(icon: .person, accessibilityLabel: "Account") {
                route = .account
            }
        }
    }

    // MARK: - Create row

    private var createRow: some View {
        HStack(spacing: 10) {
            createTile(icon: .sparkle, label: "AI plan", plasma: true) { showAI = true }
            createTile(icon: .list, label: "Starter") { showStarter = true }
            createTile(icon: .plus, label: "Build") { showBuild = true }
        }
        .padding(.horizontal, VoidSpace.insetCard)
    }

    @ViewBuilder
    private func createTile(icon: VoidIcon, label: String, plasma: Bool = false, action: @escaping () -> Void) -> some View {
        if plasma {
            Button(action: action) {
                tileLabel(icon, label, color: VoidColor.onPlasma)
                    .background(VoidColor.plasma)
                    .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: VoidRadius.tile, style: .continuous))
            }
            .buttonStyle(VoidScaleButtonStyle())
            .accessibilityLabel(label)
        } else {
            Button(action: action) {
                tileLabel(icon, label, color: VoidColor.text)
            }
            .buttonStyle(VoidPanelButtonStyle(radius: VoidRadius.tile, line: VoidColor.hairline2))
            .accessibilityLabel(label)
        }
    }

    private func tileLabel(_ icon: VoidIcon, _ label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon.systemName)
                .font(.system(size: 22, weight: .medium))
                .frame(width: 24, height: 24)
            Text(label)
                .font(.custom(VoidFont.labelFontName, size: 10))
                .tracking(1.2)
                .textCase(.uppercase)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .frame(height: VoidSize.createTile)
    }

    // MARK: - Sent to you

    private var sentSection: some View {
        VStack(spacing: 10) {
            VoidSectionRow(title: "Sent to you", trailing: viewModel.receivedTrailing, trailingColor: VoidColor.plasma)
            VoidListPanel {
                let plans = viewModel.receivedPlans
                ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                    receivedRow(plan)
                    if index < plans.count - 1 {
                        VoidHairline()
                    }
                }
            }
        }
        .padding(.top, 22)
    }

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
                VoidChevron()
            }
            .frame(height: VoidSize.listRow)
        }
        .buttonStyle(VoidRowButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                viewModel.removeReceived(plan)
            } label: {
                Label("Remove", systemImage: VoidIcon.trash.systemName)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(plan.isRead ? "" : "New")
    }

    // MARK: - Your plans

    private var yourPlansSection: some View {
        let rows = viewModel.planRows
        return VStack(spacing: 10) {
            VoidSectionRow(title: "Your plans", trailing: rows.isEmpty ? nil : "\(rows.count)")
            VoidListPanel {
                if rows.isEmpty {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(VoidColor.plasma)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, VoidSpace.s6)
                    } else {
                        VoidPlaceholder(
                            eyebrow: "No plans yet",
                            caption: "Generate one, pick a starter, build your own, or paste a link."
                        )
                    }
                } else {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        planRow(row)
                        if index < rows.count - 1 {
                            VoidHairline()
                        }
                    }
                }
            }
            if let error = viewModel.error, rows.isEmpty {
                Text(error)
                    .font(VoidFont.caption2)
                    .foregroundStyle(VoidColor.text3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, VoidSpace.insetText)
            }
        }
        .padding(.top, 22)
    }

    private func planRow(_ row: PlansHubViewModel.PlanRow) -> some View {
        Button {
            if row.isActive {
                goToActivePlan()
            } else {
                route = .preview(row.program)
            }
        } label: {
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
                VoidChevron(color: row.isActive ? VoidColor.plasma : VoidColor.text3)
            }
            .frame(height: VoidSize.listRow)
        }
        .buttonStyle(VoidRowButtonStyle())
        .overlay(alignment: .leading) {
            if row.isActive {
                UpNextMark().offset(x: -14)
            }
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
        .accessibilityElement(children: .combine)
    }

    // MARK: - Community

    private var communitySection: some View {
        VStack(spacing: 10) {
            VoidSectionRow(title: "Community", trailing: "Coming soon", trailingColor: VoidColor.text3)
            VoidListPanel {
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
                    VoidChevron()
                }
                .frame(height: VoidSize.listRow)
            }
            .opacity(0.45)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Community plans, coming soon")
        }
        .padding(.top, 22)
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

// MARK: - Routes

private enum PlansHubRoute: Hashable {
    case account
    case preview(Program)
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

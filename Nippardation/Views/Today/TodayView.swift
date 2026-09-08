//
//  TodayView.swift
//  Nippardation
//
//  Today tab: one glance, one tap. Reads icon → word → button.
//  Eyebrow row (date · streak chip), the 76pt hero tile, ▮ UP NEXT, the one Michroma word,
//  the DAY 02 / 05 readout, the giant Start, an exercises · minutes caption, and two pills.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var navigation: AppNavigation
    @StateObject private var viewModel: TodayViewModel
    @ObservedObject private var overrideStore: TodayOverrideStore
    @ObservedObject private var workoutManager = WorkoutManager.shared

    @State private var showActiveWorkout = false
    @State private var showSwapSheet = false
    @State private var previewTemplate: Template?
    @State private var didCheckForActiveWorkout = false

    init() {
        _viewModel = StateObject(wrappedValue: TodayViewModel())
        _overrideStore = ObservedObject(wrappedValue: TodayOverrideStore.shared)
    }

    /// Previews: a seeded view model and the override store it reads.
    init(viewModel: TodayViewModel, overrideStore: TodayOverrideStore) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _overrideStore = ObservedObject(wrappedValue: overrideStore)
    }

    // MARK: - Body

    var body: some View {
        let hero = heroContent

        VStack(spacing: 0) {
            VoidEyebrowRow(VoidFormat.dateEyebrow(Date())) {
                VoidChip(icon: .flame, text: "\(VoidFormat.pad2(viewModel.streakWeeks)) WK")
            }

            Spacer(minLength: VoidSpace.s3)

            heroBlock(hero)

            Spacer(minLength: VoidSpace.s3)

            // The button's glow rings overflow this 200pt footprint, as the kit's box-shadow does.
            VoidStartButton(title: hero.startTitle, isEnabled: hero.startEnabled) {
                startTapped()
            }
            .frame(width: VoidSize.start, height: VoidSize.start)

            Text(hero.caption.isEmpty ? " " : hero.caption)
                .voidReadout()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, VoidSpace.insetText)
                .padding(.top, VoidSpace.s5)

            Spacer(minLength: VoidSpace.s3)

            VoidPillPair(
                leading: "Preview Exercises",
                trailing: "Swap Workout",
                leadingEnabled: hero.previewEnabled,
                trailingEnabled: hero.swapEnabled,
                onLeading: previewTapped,
                onTrailing: { showSwapSheet = true }
            )
            .padding(.bottom, VoidSpace.pillsBottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .voidRootScreen()
        .onAppear {
            workoutManager.loadCompletedWorkouts()
            if !didCheckForActiveWorkout {
                workoutManager.checkForActiveWorkout()
                didCheckForActiveWorkout = true
            }
            overrideStore.refresh()
            viewModel.load()
        }
        .onChange(of: navigation.planRevision) { _, _ in
            viewModel.load()
        }
        .onChange(of: overrideStore.override) { _, newValue in
            viewModel.overrideDidChange(newValue)
        }
        .onChange(of: viewModel.planAdvanceCount) { _, _ in
            VoidHaptics.light()
            navigation.planDidChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("WorkoutDataUpdated"))) { _ in
            Task { @MainActor in
                await viewModel.workoutDataDidUpdate()
            }
        }
        .fullScreenCover(isPresented: $showActiveWorkout) {
            if let activeWorkout = workoutManager.activeWorkout {
                NavigationStack {
                    ActiveWorkoutView(workout: activeWorkout)
                }
            } else {
                // Race guard: nothing to resume, close the cover.
                Color.clear.onAppear { showActiveWorkout = false }
            }
        }
        .sheet(isPresented: $showSwapSheet) {
            if let program = viewModel.activeProgram {
                SwapWorkoutSheet(
                    program: program,
                    templates: Array(viewModel.planTemplates.values),
                    overrideStore: overrideStore
                )
            }
        }
        .navigationDestination(item: $previewTemplate) { template in
            WorkoutPreviewView(template: template)
        }
        .alert("Couldn't load your plan", isPresented: errorBinding) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - Hero block

    /// tile → 8 → eyebrow → 6 → word → 6 → readout, all centred.
    private func heroBlock(_ hero: HeroContent) -> some View {
        VStack(spacing: 0) {
            WorkoutTile(glyph: hero.glyph, hero: true)
                .padding(.bottom, VoidSpace.s2)
            Text(hero.eyebrow)
                .voidEyebrow(hero.eyebrowColor)
                .padding(.bottom, TodayLayout.wordGap)
            Text(hero.word)
                .voidWordHero()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, VoidSpace.insetText)
                .padding(.bottom, TodayLayout.wordGap)
            Text(hero.readout)
                .voidReadout()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, VoidSpace.insetText)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Content per state

    private var heroContent: HeroContent {
        if workoutManager.isWorkoutInProgress, let active = workoutManager.activeWorkout {
            return inProgressContent(active)
        }

        switch viewModel.mode {
        case .loading:
            return HeroContent(
                glyph: nil,
                eyebrow: "Loading",
                eyebrowColor: VoidColor.text3,
                word: "Today",
                readout: "Syncing plan",
                caption: "",
                startTitle: "Start",
                startEnabled: false,
                previewEnabled: false,
                swapEnabled: false
            )

        case .empty:
            return HeroContent(
                glyph: nil,
                eyebrow: "No plan yet",
                eyebrowColor: VoidColor.text2,
                word: "Start",
                readout: "Pick a plan to begin",
                caption: VoidFormat.readout(["AI", "Starter", "Build", "Link"]),
                startTitle: "Start",
                startEnabled: true,
                previewEnabled: false,
                swapEnabled: false
            )

        case .scheduled:
            let name = viewModel.scheduledName
            return HeroContent(
                glyph: VoidIcon.workoutGlyph(for: name),
                eyebrow: VoidGlyphs.upNext("Up next"),
                eyebrowColor: VoidColor.warning,
                word: name,
                readout: viewModel.planReadout ?? "",
                caption: TodayViewModel.caption(for: viewModel.scheduledTemplate) ?? "",
                startTitle: "Start",
                startEnabled: true,
                previewEnabled: true,
                swapEnabled: true
            )

        case .swapped:
            let name = viewModel.swappedName
            return HeroContent(
                glyph: VoidIcon.workoutGlyph(for: name),
                eyebrow: VoidGlyphs.upNext("Swapped in"),
                eyebrowColor: VoidColor.warning,
                word: name,
                readout: VoidFormat.readout(["Next", viewModel.scheduledName, viewModel.activeProgram?.name]),
                caption: TodayViewModel.caption(for: viewModel.overrideTemplate) ?? "",
                startTitle: "Start",
                startEnabled: true,
                previewEnabled: true,
                swapEnabled: true
            )

        case .rest:
            return HeroContent(
                glyph: .rest,
                eyebrow: "Rest day",
                eyebrowColor: VoidColor.text2,
                word: "Rest",
                readout: VoidFormat.readout([viewModel.scheduledName, "Tomorrow"]),
                caption: viewModel.planReadout ?? "",
                startTitle: "Start",
                startEnabled: true,
                previewEnabled: true,
                swapEnabled: true
            )
        }
    }

    private func inProgressContent(_ active: TrackedWorkout) -> HeroContent {
        let done = active.trackedExercises.reduce(0) { $0 + $1.trackedSets.count }
        let planned = workoutManager.activeWorkoutTemplate?.exercises.reduce(0) { $0 + $1.warmUpSets + $1.workingSets }
        let sets = planned.map { "\(VoidFormat.ratio(done, $0)) sets" } ?? "\(VoidFormat.pad2(done)) sets"
        let started = active.startTime.map { "Started \($0.formatted(date: .omitted, time: .shortened))" }

        return HeroContent(
            glyph: VoidIcon.workoutGlyph(for: active.workoutTemplate),
            eyebrow: VoidGlyphs.upNext("In progress"),
            eyebrowColor: VoidColor.warning,
            word: active.workoutTemplate,
            readout: VoidFormat.readout([VoidFormat.exercises(active.trackedExercises.count), sets]),
            caption: VoidFormat.readout([started, viewModel.activeProgram?.name]),
            startTitle: "Resume",
            startEnabled: true,
            previewEnabled: viewModel.mode != .loading && viewModel.mode != .empty,
            swapEnabled: false
        )
    }

    // MARK: - Actions

    private func startTapped() {
        if workoutManager.isWorkoutInProgress, workoutManager.activeWorkout != nil {
            showActiveWorkout = true
            return
        }

        switch viewModel.mode {
        case .loading:
            return
        case .empty:
            navigation.show(.plan)
        case .scheduled, .swapped, .rest:
            Task { @MainActor in
                guard let plan = await viewModel.prepareStart() else { return }
                let workout = WorkoutBuilder.workout(from: plan.template, fallbackName: plan.fallbackName)
                let tracked = workoutManager.startWorkout(template: workout)
                viewModel.didStart(tracked, plan: plan)
                showActiveWorkout = true
            }
        }
    }

    private func previewTapped() {
        Task { @MainActor in
            if let template = await viewModel.templateForPreview() {
                previewTemplate = template
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
}

// MARK: - Support types

private struct HeroContent {
    var glyph: VoidIcon?
    var eyebrow: String
    var eyebrowColor: Color
    var word: String
    var readout: String
    var caption: String
    var startTitle: String
    var startEnabled: Bool
    var previewEnabled: Bool
    var swapEnabled: Bool
}

/// Spec gaps with no VoidSpace token (HANDOFF §1: eyebrow → 6 → word → 6 → readout).
private enum TodayLayout {
    static let wordGap: CGFloat = 6
}

// MARK: - Previews

#if DEBUG
@MainActor
private func previewOverrideStore(_ name: String, override: TodayOverride?) -> TodayOverrideStore {
    let store = TodayOverrideStore(
        defaults: UserDefaults(suiteName: "today.preview.\(name)") ?? .standard,
        userIdProvider: { "preview" }
    )
    if let override {
        store.set(override)
    } else {
        store.clear()
    }
    return store
}

#Preview("With plan") {
    let store = previewOverrideStore("plan", override: nil)
    NavigationStack {
        TodayView(viewModel: .preview(program: MockData.activeProgram, store: store), overrideStore: store)
    }
    .environmentObject(AppNavigation())
    .withDependencies(.preview)
}

#Preview("Empty") {
    let store = previewOverrideStore("empty", override: nil)
    NavigationStack {
        TodayView(viewModel: .preview(program: nil, store: store, streakWeeks: 0), overrideStore: store)
    }
    .environmentObject(AppNavigation())
    .withDependencies(.preview)
}

#Preview("Rest day") {
    let store = previewOverrideStore("rest", override: .rest)
    NavigationStack {
        TodayView(viewModel: .preview(program: MockData.activeProgram, store: store), overrideStore: store)
    }
    .environmentObject(AppNavigation())
    .withDependencies(.preview)
}

#Preview("In progress") {
    let store = previewOverrideStore("progress", override: nil)
    let _ = WorkoutManager.shared.startWorkout(template: WorkoutBuilder.workout(from: MockData.pullTemplate))
    NavigationStack {
        TodayView(viewModel: .preview(program: MockData.activeProgram, store: store), overrideStore: store)
    }
    .environmentObject(AppNavigation())
    .withDependencies(.preview)
}
#endif

//
//  SwapWorkoutSheet.swift
//  Nippardation
//
//  Swap Workout: a sheet listing every workout in the plan plus a Rest day and a
//  Skip workout row. Picking a workout runs it today in place of the scheduled one (which
//  stays next in the rotation); Rest day pushes today's workout to tomorrow; Skip workout
//  drops it and moves the plan on, so the rotation records it as SKIPPED rather than DONE.
//  Selecting dismisses immediately. A standard grouped list: today's choice carries the
//  checkmark, and the close button sits in the navigation bar.
//

import SwiftUI

struct SwapWorkoutSheet: View {
    let program: Program
    /// Resolved templates for the plan's workouts (names fall back to the embedded template / day label).
    var templates: [Template] = []
    /// Runs the skip. Nil hides the Skip workout row (nothing to skip, or a workout is running).
    var onSkip: (() -> Void)?
    /// The workout the plan moves to after a skip, for the confirmation copy.
    var nextAfterSkipName: String = ""
    @ObservedObject private var overrideStore: TodayOverrideStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showSkipConfirmation = false
    /// Where the person dragged the sheet; nil until they do, so it opens at `openingDetent`.
    @State private var draggedDetent: PresentationDetent?

    /// Rows that fit below the navigation bar at half height on the smallest supported phone
    /// (375×667) at the default text size.
    static let rowsVisibleAtHalfHeight = 3

    init(
        program: Program,
        templates: [Template] = [],
        overrideStore: TodayOverrideStore = .shared,
        nextAfterSkipName: String = "",
        onSkip: (() -> Void)? = nil
    ) {
        self.program = program
        self.templates = templates
        self.nextAfterSkipName = nextAfterSkipName
        self.onSkip = onSkip
        _overrideStore = ObservedObject(wrappedValue: overrideStore)
    }

    // MARK: - Derived

    private var workouts: [ProgramWorkout] {
        program.workouts.sorted { $0.dayNumber < $1.dayNumber }
    }

    private var scheduled: (workout: ProgramWorkout, index: Int)? {
        TodayViewModel.scheduledSlot(in: program)
    }

    private var scheduledName: String {
        guard let scheduled else { return "Workout" }
        return name(for: scheduled.workout, index: scheduled.index)
    }

    /// The row Today currently resolves to (nil while Rest day is selected).
    private var todayRowId: UUID? {
        switch overrideStore.override {
        case .some(.rest):
            return nil
        case .some(.template(let serverId)):
            if serverId == scheduled?.workout.templateServerId { return scheduled?.workout.id }
            return workouts.first { $0.templateServerId == serverId }?.id ?? scheduled?.workout.id
        case .none:
            return scheduled?.workout.id
        }
    }

    private var isRestSelected: Bool {
        overrideStore.override?.isRest == true
    }

    private var dayReadout: String {
        "Day \(VoidFormat.ratio((scheduled?.index ?? 0) + 1, max(1, workouts.count)))"
    }

    private func template(for workout: ProgramWorkout) -> Template? {
        templates.first { $0.serverId == workout.templateServerId } ?? workout.template
    }

    private func name(for workout: ProgramWorkout, index: Int) -> String {
        TodayViewModel.word(workout: workout, template: template(for: workout), index: index)
    }

    /// Every workout, then Rest day, then Skip workout when it's offered.
    private var rowCount: Int {
        workouts.count + (onSkip == nil ? 1 : 2)
    }

    /// Half height while every row fits there; otherwise full height, so Rest day and Skip
    /// workout don't open below the fold. Accessibility text sizes always open at full height.
    static func openingDetent(rowCount: Int, dynamicTypeSize: DynamicTypeSize) -> PresentationDetent {
        rowCount <= rowsVisibleAtHalfHeight && !dynamicTypeSize.isAccessibilitySize ? .medium : .large
    }

    private var detent: Binding<PresentationDetent> {
        Binding(
            get: { draggedDetent ?? Self.openingDetent(rowCount: rowCount, dynamicTypeSize: dynamicTypeSize) },
            set: { draggedDetent = $0 }
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                        workoutRow(workout, index: index)
                    }
                } header: {
                    HStack(alignment: .firstTextBaseline) {
                        Text(program.name)
                            .lineLimit(1)
                        Spacer(minLength: VoidSpace.s3)
                        Text(dayReadout)
                    }
                }

                Section {
                    restRow
                    if onSkip != nil {
                        skipRow
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Swap workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SheetCloseButton {
                        dismiss()
                    }
                }
            }
        }
        // Opens at half height only when every row fits there (see `openingDetent`); either way
        // the sheet drags between half and full height.
        .presentationDetents([.medium, .large], selection: detent)
        .presentationDragIndicator(.visible)
    }

    /// Says plainly what a skip costs — it is not a rest day, and it is not a completion.
    private var skipConfirmationMessage: String {
        let next = nextAfterSkipName.isEmpty ? "the next workout" : nextAfterSkipName
        return "This won't be logged and won't count toward your streak. Your plan moves on to \(next)."
    }

    // MARK: - Rows

    private func workoutRow(_ workout: ProgramWorkout, index: Int) -> some View {
        let isScheduled = workout.id == scheduled?.workout.id
        let isToday = workout.id == todayRowId
        let title = name(for: workout, index: index)
        let day = "Day \(VoidFormat.pad2(index + 1))"

        return Button {
            select(workout)
        } label: {
            HStack(spacing: VoidSpace.s3) {
                VStack(alignment: .leading, spacing: VoidSpace.s1) {
                    Text(isScheduled ? VoidGlyphs.upNext("\(day)\(VoidFormat.dot)Up next") : day)
                        .voidEyebrowSm(isScheduled ? VoidColor.warning : VoidColor.text2)
                    Text(title)
                        .font(VoidFont.title)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: VoidSpace.s2)
                if isToday {
                    todayMark
                }
            }
        }
        .accessibilityLabel(isToday ? "\(title), today" : title)
        .accessibilityAddTraits(isToday ? [.isSelected] : [])
    }

    private var restRow: some View {
        Button {
            overrideStore.set(.rest)
            dismiss()
        } label: {
            HStack(spacing: VoidSpace.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest day")
                        .font(VoidFont.title)
                        .foregroundStyle(VoidColor.text)
                    Text("Skip today\(VoidFormat.dot)\(scheduledName) moves to tomorrow")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: VoidSpace.s2)
                if isRestSelected {
                    todayMark
                }
            }
        }
        .accessibilityLabel(isRestSelected ? "Rest day, today" : "Rest day")
        .accessibilityAddTraits(isRestSelected ? [.isSelected] : [])
    }

    /// Opens the confirmation; the dialog hangs off this row so iOS 26 anchors it here.
    private var skipRow: some View {
        Button {
            showSkipConfirmation = true
        } label: {
            HStack(spacing: VoidSpace.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Skip workout")
                        .font(VoidFont.title)
                        .foregroundStyle(VoidColor.text)
                    Text("Don't do it\(VoidFormat.dot)Plan moves on, nothing logged")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: VoidSpace.s2)
                Image(systemName: VoidIcon.skip.systemName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(VoidColor.text3)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel("Skip workout")
        .accessibilityHint("Moves the plan past \(scheduledName) without logging it")
        .confirmationDialog(
            "Skip \(scheduledName)?",
            isPresented: $showSkipConfirmation,
            titleVisibility: .visible
        ) {
            Button("Skip workout", role: .destructive) {
                onSkip?()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(skipConfirmationMessage)
        }
    }

    /// "Today" + the list's checkmark in plasma. The check is a glyph colour, not a fill.
    private var todayMark: some View {
        HStack(spacing: VoidSpace.s2) {
            Text("Today")
                .font(VoidFont.caption2)
                .foregroundStyle(VoidColor.text2)
            Image(systemName: VoidIcon.check.systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(VoidColor.plasma)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Selection

    private func select(_ workout: ProgramWorkout) {
        if let scheduled, workout.templateServerId == scheduled.workout.templateServerId {
            overrideStore.clear()
        } else {
            overrideStore.set(.template(serverId: workout.templateServerId))
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("Swap workout") {
    let store = TodayOverrideStore(
        defaults: UserDefaults(suiteName: "swap.preview") ?? .standard,
        userIdProvider: { "preview" }
    )
    VoidColor.hull
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SwapWorkoutSheet(
                program: MockData.activeProgram,
                templates: MockData.templates,
                overrideStore: store,
                nextAfterSkipName: "Legs",
                onSkip: { }
            )
        }
}

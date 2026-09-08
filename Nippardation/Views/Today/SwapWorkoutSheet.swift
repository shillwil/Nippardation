//
//  SwapWorkoutSheet.swift
//  Nippardation
//
//  Swap Workout: a bottom sheet listing every workout in the plan plus a final Rest day row.
//  Picking a workout runs it today in place of the scheduled one (which stays next in the
//  rotation); Rest day skips today. Selecting dismisses immediately.
//

import SwiftUI

struct SwapWorkoutSheet: View {
    let program: Program
    /// Resolved templates for the plan's workouts (names fall back to the embedded template / day label).
    var templates: [Template] = []
    @ObservedObject private var overrideStore: TodayOverrideStore
    @Environment(\.dismiss) private var dismiss

    /// HANDOFF: swap rows are 58pt (no VoidSize token).
    private static let rowHeight: CGFloat = 58

    init(program: Program, templates: [Template] = [], overrideStore: TodayOverrideStore = .shared) {
        self.program = program
        self.templates = templates
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

    /// Sheet height that fits every row; falls back to system detents for long plans.
    private var detents: Set<PresentationDetent> {
        let grabber: CGFloat = 10 + VoidSize.grabber.height + 22
        let header: CGFloat = 16 + VoidSpace.s4
        let rows = CGFloat(workouts.count + 1) * Self.rowHeight + CGFloat(workouts.count)
        let height = grabber + header + rows + 34
        return height > 560 ? [.medium, .large] : [.height(height)]
    }

    // MARK: - Body

    var body: some View {
        VoidSheetContainer {
            VStack(spacing: 0) {
                HStack {
                    Text("Swap workout").voidEyebrow()
                    Spacer(minLength: VoidSpace.s3)
                    Text(dayReadout).voidEyebrow()
                }
                .padding(.bottom, VoidSpace.s4)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                            workoutRow(workout, index: index)
                            VoidHairline()
                        }
                        restRow
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(VoidColor.panel)
        .voidSheet()
        .presentationDetents(detents)
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
            .frame(height: Self.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidRowButtonStyle())
        .accessibilityLabel(isToday ? "\(title), today" : title)
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
            .frame(height: Self.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidRowButtonStyle())
        .accessibilityLabel(isRestSelected ? "Rest day, today" : "Rest day")
    }

    /// "Today" + a plasma check. The check is a glyph colour, not a fill.
    private var todayMark: some View {
        HStack(spacing: VoidSpace.s2) {
            Text("Today")
                .font(VoidFont.caption2)
                .foregroundStyle(VoidColor.text2)
            Image(systemName: VoidIcon.check.systemName)
                .font(.system(size: 15, weight: .bold))
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
            SwapWorkoutSheet(program: MockData.activeProgram, templates: MockData.templates, overrideStore: store)
        }
}

//
//  ProgressTabView.swift
//  Nippardation
//
//  The Progress tab (Void screen 3): streak hero, 2×2 stat grid, workouts-per-week chart,
//  as rows of a grouped list under a large "Progress" title. The Me / Crew switch is a
//  segmented control in the navigation bar. Me is live; Crew shows the standard empty
//  state until the friends leaderboard ships.
//  Named ProgressTabView because ProgressView is SwiftUI's spinner.
//

import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject private var navigation: AppNavigation
    @StateObject private var viewModel: ProgressViewModel
    @ObservedObject private var workoutManager = WorkoutManager.shared
    @ObservedObject private var bodyWeight = BodyWeightStore.shared

    @State private var showBodyWeightSheet = false

    init() {
        _viewModel = StateObject(wrappedValue: ProgressViewModel())
    }

    /// Preview / test hook: inject a view model with pinned data.
    init(viewModel: ProgressViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            if viewModel.scope == .me {
                meSection
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.scope == .crew {
                crewUnavailable
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // The Phone app's Recents pattern: the scope switch in the bar, the large title below.
            ToolbarItem(placement: .principal) {
                scopePicker
            }
        }
        .voidScreen()
        .onAppear {
            workoutManager.loadCompletedWorkouts()
            viewModel.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("WorkoutDataUpdated"))) { _ in
            viewModel.refresh()
        }
        .onChange(of: workoutManager.completedWorkouts) { _, _ in
            viewModel.recompute()
        }
        .onChange(of: navigation.planRevision) { _, _ in
            viewModel.refresh()
        }
        .sheet(isPresented: $showBodyWeightSheet) {
            BodyWeightSheet()
        }
    }

    // MARK: - Scope

    private var scopePicker: some View {
        Picker("Progress scope", selection: $viewModel.scope) {
            ForEach(ProgressScope.allCases, id: \.self) { scope in
                Text(scope.label).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .fixedSize()
    }

    // MARK: - Me

    /// The dashboard pieces draw their own panels, so each is a bare list row: no cell
    /// background, no separator, edges on the list's margins (in line with the large title).
    private var meSection: some View {
        Section {
            streakHero
                .dashboardRow(top: 0)

            statGrid
                .dashboardRow(top: VoidSpace.s6)

            chartCard
                .dashboardRow(top: 10)
        }
    }

    /// 64pt flame tile, 16pt gap, then the streak count over its eyebrow.
    private var streakHero: some View {
        HStack(spacing: VoidSpace.s4) {
            ZStack {
                // Hero panels use the 16pt radius.
                RoundedRectangle(cornerRadius: VoidRadius.tabBar, style: .continuous)
                    .fill(VoidColor.panel)
                RoundedRectangle(cornerRadius: VoidRadius.tabBar, style: .continuous)
                    .strokeBorder(VoidColor.hairline2, lineWidth: 1)
                Image(systemName: VoidIcon.flame.systemName)
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.medium)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(VoidColor.text)
            }
            .frame(width: VoidSize.tileStreak, height: VoidSize.tileStreak)

            VStack(alignment: .leading, spacing: VoidSpace.s1) {
                Text(viewModel.streakValue)
                    .voidNumberHero()
                Text(viewModel.streakCaption)
                    .voidEyebrow()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.streakAccessibilityLabel)
    }

    /// Volume · PRs / Plan · Body.
    private var statGrid: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                VoidStatTile(
                    icon: .barbell,
                    value: viewModel.volumeValue.number,
                    unit: viewModel.volumeValue.unit,
                    label: viewModel.volumeLabel
                )
                VoidStatTile(
                    icon: .medal,
                    value: viewModel.prsValue,
                    label: "PRs this week",
                    tone: VoidColor.warning
                )
            }
            GridRow {
                VoidStatTile(
                    icon: .calendarCheck,
                    value: viewModel.planValue,
                    unit: viewModel.planUnit,
                    label: viewModel.planLabel,
                    progress: viewModel.planProgress
                )
                // Plain style: the tile draws itself, and inside a list row only the tile
                // (not the whole row of tiles) takes the tap.
                Button {
                    showBodyWeightSheet = true
                } label: {
                    VoidStatTile(
                        icon: .scale,
                        value: viewModel.bodyValue(latest: bodyWeight.latest),
                        label: viewModel.bodyLabel(latest: bodyWeight.latest, delta: bodyWeight.delta)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the body weight log")
            }
        }
    }

    /// WORKOUTS / WEEK … 08 WK over eight bars; the current week is plasma.
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s3) {
            HStack {
                Text("Workouts / week").voidEyebrowSm()
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(viewModel.chartWeeksLabel).voidEyebrowSm()
            }
            VoidBarChart(
                values: viewModel.stats.weeklyRatios,
                currentIndex: ProgressStatsCalculator.chartWeeks - 1
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(viewModel.chartAccessibilityLabel)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, VoidSpace.s4)
        .voidPanel(radius: VoidRadius.panel, line: VoidColor.hairline)
    }

    // MARK: - Crew

    /// Crew fills the tab until the friends leaderboard ships, so it is a whole-screen empty state.
    private var crewUnavailable: some View {
        ContentUnavailableView(
            "Crew is coming soon",
            systemImage: "person.2",
            description: Text("Friends leaderboard.")
        )
    }
}

private extension View {
    /// A Progress dashboard row: content that draws its own panel, sitting `top` points below
    /// the row above, with no list cell background or separator.
    func dashboardRow(top: CGFloat) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

// MARK: - Preview data

/// Eight weeks of fabricated history so the preview shows a streak, PRs and a full chart.
private enum ProgressPreviewData {
    static var workouts: [TrackedWorkout] {
        let calendar = VoidCalendar.current
        let now = Date()
        let perWeek = [4, 5, 3, 6, 4, 5, 5, 4]
        var result: [TrackedWorkout] = []

        for weekOffset in 0..<ProgressStatsCalculator.chartWeeks {
            let weekStart = VoidCalendar.weekInterval(offset: weekOffset, from: now, calendar: calendar).start
            let bump = Double(ProgressStatsCalculator.chartWeeks - weekOffset) * 5
            for day in 0..<perWeek[weekOffset] {
                guard let date = calendar.date(byAdding: .day, value: day, to: weekStart), date <= now else { continue }
                result.append(
                    TrackedWorkout(
                        date: date,
                        workoutTemplate: ["Push", "Pull", "Legs"][day % 3],
                        duration: 55 * 60,
                        trackedExercises: [
                            exercise("Bench Press", muscles: [.chest, .triceps], weight: 165 + bump, reps: 8),
                            exercise("Back Squat", muscles: [.quads, .glutes], weight: 205 + bump, reps: 6),
                            exercise("Barbell Row", muscles: [.back, .biceps], weight: 125 + bump, reps: 10)
                        ],
                        isCompleted: true
                    )
                )
            }
        }
        return result
    }

    private static func exercise(_ name: String, muscles: [MuscleGroup], weight: Double, reps: Int) -> TrackedExercise {
        let type = ExerciseType(name: name, muscleGroup: muscles)
        let sets = (0..<3).map { _ in
            TrackedSet(reps: reps, weight: weight, setType: .working, exerciseType: type)
        }
        return TrackedExercise(exerciseName: name, muscleGroups: muscles.map(\.rawValue), trackedSets: sets)
    }
}

// MARK: - Previews

#Preview("With data") {
    NavigationStack {
        ProgressTabView(
            viewModel: ProgressViewModel(
                programRepository: DependencyContainer.preview.programRepository,
                workoutsProvider: { ProgressPreviewData.workouts },
                planSource: .fixed(MockProgramRepository.samplePrograms.first)
            )
        )
    }
    .environmentObject(AppNavigation())
    .withDependencies(.preview)
}

#Preview("Empty") {
    NavigationStack {
        ProgressTabView(
            viewModel: ProgressViewModel(
                programRepository: DependencyContainer.preview.programRepository,
                workoutsProvider: { [] },
                planSource: .fixed(nil)
            )
        )
    }
    .environmentObject(AppNavigation())
    .withDependencies(.preview)
}

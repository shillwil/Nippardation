//
//  ProgressTabView.swift
//  Nippardation
//
//  The Progress tab (Void screen 3): streak hero, 2×2 stat grid, workouts-per-week chart.
//  Me is live; Crew is a placeholder panel until the friends leaderboard ships.
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
        ScrollView {
            VStack(spacing: 0) {
                VoidEyebrowRow("Progress") {
                    VoidSegmentedControl(
                        items: [ProgressScope.me, .crew],
                        label: { $0.label },
                        selection: $viewModel.scope
                    )
                }

                switch viewModel.scope {
                case .me:
                    meContent
                case .crew:
                    crewContent
                }
            }
            .padding(.bottom, VoidSpace.s6)
        }
        .voidRootScreen()
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

    // MARK: - Me

    private var meContent: some View {
        VStack(spacing: 0) {
            streakHero
                .padding(.top, 26)
                .padding(.horizontal, VoidSpace.insetText)

            statGrid
                .padding(.top, VoidSpace.s6)
                .padding(.horizontal, VoidSpace.insetCard)

            chartCard
                .padding(.top, 10)
                .padding(.horizontal, VoidSpace.insetCard)
        }
    }

    /// 64pt flame tile, 16pt gap, then the streak count over its eyebrow.
    private var streakHero: some View {
        HStack(spacing: VoidSpace.s4) {
            ZStack {
                // Hero panels share the 16pt radius with the tab bar.
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
                Button {
                    showBodyWeightSheet = true
                } label: {
                    VoidStatTile(
                        icon: .scale,
                        value: viewModel.bodyValue(latest: bodyWeight.latest),
                        label: viewModel.bodyLabel(latest: bodyWeight.latest, delta: bodyWeight.delta)
                    )
                }
                .buttonStyle(VoidPlainButtonStyle())
                .accessibilityHint("Opens the body weight log")
            }
        }
    }

    /// WORKOUTS / WEEK … 08 WK over eight bars; the current week is plasma.
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s3) {
            HStack {
                Text("Workouts / week").voidEyebrowSm()
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

    private var crewContent: some View {
        VoidListPanel {
            VoidPlaceholder(eyebrow: "CREW · COMING SOON", caption: "Friends leaderboard.")
        }
        .opacity(0.45)
        .padding(.top, 26)
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

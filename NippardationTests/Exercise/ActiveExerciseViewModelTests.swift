//
//  ActiveExerciseViewModelTests.swift
//  NippardationTests
//
//  The exercise sheet's view model: Complete exercise and what reopens an exercise, which
//  bottom button leads, which exercise comes next, and how the Example video is found.
//  Every view model here works on its own copy of the workout, with no WorkoutManager, so
//  nothing reads or writes the workout in progress.
//

import Testing
import Foundation
@testable import Nippardation

/// Answers every lookup with `answer`, a beat late, and still answers once cancelled, as
/// ExerciseRepository does: it catches a cancelled request and returns its cached copy.
@MainActor
private final class LateExerciseRepository: ExerciseRepositoryProtocol {
    let answer: ExerciseLibraryItem

    init(answer: ExerciseLibraryItem) {
        self.answer = answer
    }

    private func wait() async {
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    func fetchExercises(filter: ExerciseFilter?, page: Int, forceRefresh: Bool) async throws -> PaginatedResult<ExerciseLibraryItem> {
        await wait()
        return PaginatedResult(items: [answer], page: page, totalPages: 1, totalItems: 1)
    }

    func fetchExercise(serverId: String, forceRefresh: Bool) async throws -> ExerciseLibraryItem {
        await wait()
        return answer
    }

    func searchExercises(query: String, limit: Int) async throws -> [ExerciseLibraryItem] {
        await wait()
        return [answer]
    }

    func getCachedExercises(filter: ExerciseFilter?) -> [ExerciseLibraryItem] {
        [answer]
    }

    func getCachedExercise(serverId: String) -> ExerciseLibraryItem? {
        answer
    }

    func clearCache() async throws {}

    func fetchPopularExercises(limit: Int) async throws -> [ExerciseLibraryItem] {
        [answer]
    }

    func fetchExercisesByMuscle(_ muscleGroup: MuscleGroup, limit: Int) async throws -> [ExerciseLibraryItem] {
        [answer]
    }
}

@Suite("Active exercise view model")
@MainActor
struct ActiveExerciseViewModelTests {

    /// MockExerciseRepository's Barbell Bench Press (ex_001).
    private let benchVideo = URL(string: "https://example.com/videos/bench_press.mp4")!

    // MARK: - Fixtures

    /// The view model for `exercises[index]`. With no template, a name no template knows gets
    /// the fallback targets: 0 warm-up + 3 working sets.
    private func makeViewModel(
        _ exercises: [TrackedExercise],
        at index: Int = 0,
        template: Workout? = nil,
        repository: (any ExerciseRepositoryProtocol)? = nil
    ) -> ActiveExerciseViewModel {
        ActiveExerciseViewModel(
            workout: VoidFixtures.workout(on: VoidFixtures.now, exercises: exercises, completed: false),
            exerciseIndex: index,
            exerciseRepository: repository ?? MockExerciseRepository(),
            template: template,
            workoutManager: nil
        )
    }

    /// A stored plan template holding one exercise.
    private func template(
        for name: String,
        warmUpSets: Int = 1,
        workingSets: Int = 3,
        serverId: String? = nil,
        example: String = ""
    ) -> Workout {
        Workout(name: "Test Day", exercises: [
            Exercise(
                type: ExerciseType(name: name, muscleGroup: [.chest]),
                exerciseServerId: serverId,
                example: example,
                lastSetIntensityTechnique: "Failure",
                warmUpSets: warmUpSets,
                workingSets: workingSets,
                reps: 8...12,
                rest: 2...3
            )
        ])
    }

    private func completed(_ name: String) -> TrackedExercise {
        var exercise = VoidFixtures.exercise(name, sets: [VoidFixtures.set(8, 135)])
        exercise.completedAt = VoidFixtures.now
        return exercise
    }

    private func libraryItem(_ name: String, serverId: String, video: String) -> ExerciseLibraryItem {
        ExerciseLibraryItem(
            id: UUID(),
            serverId: serverId,
            name: name,
            primaryMuscles: [.back],
            secondaryMuscles: [],
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .pull,
            exerciseType: .compound,
            instructions: nil,
            videoUrl: URL(string: video),
            thumbnailUrl: nil,
            popularityScore: 0,
            lastFetchedAt: nil
        )
    }

    // MARK: - Complete exercise

    @Test func completingKeepsTheFirstTime() {
        let viewModel = makeViewModel([VoidFixtures.exercise("Test Press", sets: [VoidFixtures.set(8, 135)])])
        let first = VoidFixtures.now
        let later = first.addingTimeInterval(600)

        viewModel.markComplete(at: first)
        #expect(viewModel.currentExercise?.completedAt == first)
        #expect(viewModel.currentExercise?.isCompleted == true)

        viewModel.markComplete(at: later)
        #expect(viewModel.currentExercise?.completedAt == first)
    }

    /// Complete needs a set, so deleting the only one reopens the exercise.
    @Test func deletingTheOnlySetReopensACompletedExercise() {
        let viewModel = makeViewModel([VoidFixtures.exercise("Test Press", sets: [VoidFixtures.set(8, 135)])])
        viewModel.markComplete(at: VoidFixtures.now)

        viewModel.deleteSet(at: 0)

        #expect(viewModel.currentExercise?.trackedSets.isEmpty == true)
        #expect(viewModel.currentExercise?.completedAt == nil)
        #expect(viewModel.currentExercise?.isCompleted == false)
    }

    @Test func deletingOneOfSeveralSetsKeepsItCompleted() {
        let viewModel = makeViewModel([
            VoidFixtures.exercise("Test Press", sets: [VoidFixtures.set(8, 135), VoidFixtures.set(6, 155)])
        ])
        viewModel.markComplete(at: VoidFixtures.now)

        viewModel.deleteSet(at: 0)

        #expect(viewModel.currentExercise?.trackedSets.count == 1)
        #expect(viewModel.currentExercise?.completedAt == VoidFixtures.now)
    }

    @Test func completingOnlyTouchesTheCurrentExercise() {
        let viewModel = makeViewModel([
            VoidFixtures.exercise("Test Press", sets: [VoidFixtures.set(8, 135)]),
            VoidFixtures.exercise("Test Row", sets: [VoidFixtures.set(10, 95)])
        ], at: 1)

        viewModel.markComplete(at: VoidFixtures.now)

        #expect(viewModel.workout.trackedExercises[0].completedAt == nil)
        #expect(viewModel.workout.trackedExercises[1].completedAt == VoidFixtures.now)
    }

    @Test func withNoExerciseCompletingDoesNothing() {
        let viewModel = makeViewModel([])

        viewModel.markComplete(at: VoidFixtures.now)
        viewModel.deleteSet(at: 0)

        #expect(viewModel.isValidExercise == false)
        #expect(viewModel.currentExercise == nil)
        #expect(viewModel.workout.trackedExercises.isEmpty)
    }

    // MARK: - Bottom buttons

    /// The target is the template's warm-up plus working sets (1 + 3 here).
    @Test func addSetLeadsUntilTheTemplatesSetsAreIn() {
        let viewModel = makeViewModel(
            [VoidFixtures.exercise("Test Press", sets: [])],
            template: template(for: "Test Press", warmUpSets: 1, workingSets: 3)
        )
        #expect(viewModel.ctaState == ExerciseCTAState(loggedSets: 0, targetSets: 4, hasExercise: true))
        #expect(viewModel.ctaState.addSetIsPrimary)
        #expect(viewModel.ctaState.canComplete == false)

        for _ in 0..<3 {
            viewModel.addSet(VoidFixtures.set(8, 135))
        }
        #expect(viewModel.ctaState == ExerciseCTAState(loggedSets: 3, targetSets: 4, hasExercise: true))
        #expect(viewModel.ctaState.addSetIsPrimary)
        #expect(viewModel.ctaState.canComplete)

        viewModel.addSet(VoidFixtures.set(8, 135))
        #expect(viewModel.ctaState.completeIsPrimary)
        #expect(viewModel.ctaState.addSetIsPrimary == false)
        #expect(viewModel.ctaState.canAddSet)
    }

    /// An exercise no template knows falls back to 0 warm-up + 3 working sets.
    @Test func anUnknownExerciseTargetsThreeSets() {
        let viewModel = makeViewModel([
            VoidFixtures.exercise("Test Press", sets: [VoidFixtures.set(8, 135), VoidFixtures.set(8, 135)])
        ])
        #expect(viewModel.ctaState == ExerciseCTAState(loggedSets: 2, targetSets: 3, hasExercise: true))
        #expect(viewModel.ctaState.addSetIsPrimary)

        viewModel.addSet(VoidFixtures.set(8, 135))
        #expect(viewModel.ctaState.completeIsPrimary)
    }

    /// Deleting back below the target hands the lead back to Add set; deleting every set
    /// disables Complete.
    @Test func deletingSetsHandsTheLeadBack() {
        let viewModel = makeViewModel([
            VoidFixtures.exercise("Test Press", sets: [VoidFixtures.set(8, 135), VoidFixtures.set(8, 135), VoidFixtures.set(8, 135)])
        ])
        #expect(viewModel.ctaState.completeIsPrimary)

        viewModel.deleteSet(at: 2)
        #expect(viewModel.ctaState.addSetIsPrimary)
        #expect(viewModel.ctaState.canComplete)

        viewModel.deleteSet(at: 1)
        viewModel.deleteSet(at: 0)
        #expect(viewModel.ctaState.canComplete == false)
    }

    @Test func withNoExerciseNeitherButtonWorks() {
        let viewModel = makeViewModel([])

        #expect(viewModel.matchingExercise == nil)
        #expect(viewModel.ctaState == ExerciseCTAState(loggedSets: 0, targetSets: 0, hasExercise: false))
        #expect(viewModel.ctaState.canAddSet == false)
        #expect(viewModel.ctaState.canComplete == false)
    }

    // MARK: - Next exercise

    @Test func nextIsTheFollowingUnfinishedExercise() {
        let open = VoidFixtures.exercise("Test Curl", sets: [])
        let viewModel = makeViewModel([
            completed("Test Press"),
            VoidFixtures.exercise("Test Row", sets: [VoidFixtures.set(10, 95)]),
            completed("Test Squat"),
            open
        ], at: 1)

        #expect(viewModel.nextExercise?.id == open.id)
    }

    /// One skipped earlier (a busy machine) comes up after the last.
    @Test func nextWrapsToAnExerciseSkippedEarlier() {
        let skipped = VoidFixtures.exercise("Test Press", sets: [])
        let viewModel = makeViewModel([
            skipped,
            completed("Test Row"),
            VoidFixtures.exercise("Test Squat", sets: [VoidFixtures.set(5, 225)])
        ], at: 2)

        #expect(viewModel.nextExercise?.id == skipped.id)
    }

    @Test func nothingIsNextWhenEverythingElseIsDone() {
        let viewModel = makeViewModel([
            completed("Test Press"),
            completed("Test Row"),
            VoidFixtures.exercise("Test Squat", sets: [VoidFixtures.set(5, 225)])
        ], at: 2)
        #expect(viewModel.nextExercise == nil)

        viewModel.markComplete(at: VoidFixtures.now)
        #expect(viewModel.nextExercise == nil)
        #expect(makeViewModel([]).nextExercise == nil)
    }

    @Test func nextFollowsExerciseProgression() {
        let exercises = [
            VoidFixtures.exercise("Test Press", sets: []),
            completed("Test Row"),
            VoidFixtures.exercise("Test Squat", sets: [VoidFixtures.set(5, 225)]),
            completed("Test Curl")
        ]

        for index in exercises.indices {
            let expected = ExerciseProgression.nextUnfinishedIndex(after: index, in: exercises).map { exercises[$0].id }
            #expect(makeViewModel(exercises, at: index).nextExercise?.id == expected)
        }
    }

    // MARK: - Example video

    /// A plan exercise plays the URL snapshotted at workout start straight away (its file is
    /// cached under the same serverId), instead of a spinner while the current URL is fetched.
    @Test func aPlanExerciseShowsItsSnapshotAtOnce() async {
        let repository = MockExerciseRepository()
        repository.setDelay(0.05)
        let viewModel = makeViewModel(
            [VoidFixtures.exercise("Test Press", sets: [])],
            template: template(for: "Test Press", serverId: "ex_001", example: benchVideo.absoluteString),
            repository: repository
        )

        #expect(viewModel.nativeVideoUrl == benchVideo)
        #expect(viewModel.exerciseServerId == "ex_001")
        #expect(viewModel.isResolvingVideo == false)

        await viewModel.videoLookupTask?.value
        #expect(viewModel.nativeVideoUrl == benchVideo)
        #expect(viewModel.isResolvingVideo == false)
    }

    @Test func theCurrentURLReplacesARenamedSnapshot() async {
        let stale = URL(string: "https://example.com/videos/bench_press_old.mp4")!
        let viewModel = makeViewModel(
            [VoidFixtures.exercise("Test Press", sets: [])],
            template: template(for: "Test Press", serverId: "ex_001", example: stale.absoluteString)
        )
        #expect(viewModel.nativeVideoUrl == stale)

        await viewModel.videoLookupTask?.value

        #expect(viewModel.nativeVideoUrl == benchVideo)
    }

    @Test func aFailedRefreshKeepsTheSnapshot() async {
        let repository = MockExerciseRepository()
        repository.setFailure(true)
        let viewModel = makeViewModel(
            [VoidFixtures.exercise("Test Press", sets: [])],
            template: template(for: "Test Press", serverId: "ex_001", example: benchVideo.absoluteString),
            repository: repository
        )

        await viewModel.videoLookupTask?.value

        #expect(viewModel.nativeVideoUrl == benchVideo)
        #expect(viewModel.isResolvingVideo == false)
    }

    /// With no snapshot there's nothing to show, so the spinner holds until the URL arrives.
    @Test func withoutASnapshotTheSpinnerWaitsForTheURL() async {
        let viewModel = makeViewModel(
            [VoidFixtures.exercise("Test Press", sets: [])],
            template: template(for: "Test Press", serverId: "ex_001", example: "")
        )
        #expect(viewModel.isResolvingVideo)
        #expect(viewModel.nativeVideoUrl == nil)

        await viewModel.videoLookupTask?.value

        #expect(viewModel.isResolvingVideo == false)
        #expect(viewModel.nativeVideoUrl == benchVideo)
        #expect(viewModel.exerciseServerId == "ex_001")
    }

    /// A legacy exercise (no serverId) finds its video by an exact name match.
    @Test func aLegacyExerciseFindsItsVideoByName() async {
        let match = libraryItem("Test Press", serverId: "ex_press", video: "https://example.com/videos/press.mp4")
        let viewModel = makeViewModel(
            [VoidFixtures.exercise("Test Press", sets: [])],
            repository: LateExerciseRepository(answer: match)
        )
        #expect(viewModel.isResolvingVideo)

        await viewModel.videoLookupTask?.value

        #expect(viewModel.isResolvingVideo == false)
        #expect(viewModel.nativeVideoUrl == match.videoUrl)
        #expect(viewModel.exerciseServerId == "ex_press")
    }

    /// Swap movement while the old movement's lookup is in flight: its late answer (the
    /// repository returns its cached copy even once cancelled) must not replace the new
    /// movement's video, and the spinner goes at once.
    @Test func aSwapDropsTheOldMovementsLateLookup() async throws {
        let old = libraryItem("Test Press", serverId: "ex_press", video: "https://example.com/videos/press.mp4")
        let viewModel = makeViewModel(
            [VoidFixtures.exercise("Test Press", sets: [])],
            template: template(for: "Test Press", serverId: "ex_press", example: ""),
            repository: LateExerciseRepository(answer: old)
        )
        let pending = try #require(viewModel.videoLookupTask)
        #expect(viewModel.isResolvingVideo)

        let replacement = libraryItem("Test Row", serverId: "ex_row", video: "https://example.com/videos/row.mp4")
        viewModel.swapExercise(to: replacement)
        #expect(viewModel.isResolvingVideo == false)

        await pending.value

        #expect(viewModel.nativeVideoUrl == replacement.videoUrl)
        #expect(viewModel.exerciseServerId == "ex_row")
        #expect(viewModel.isResolvingVideo == false)
        #expect(viewModel.currentExercise?.exerciseName == "Test Row")
    }

    /// The same for a legacy exercise's name search, which would also overwrite the serverId.
    @Test func aSwapDropsTheOldMovementsLateNameSearch() async throws {
        let old = libraryItem("Test Press", serverId: "ex_press", video: "https://example.com/videos/press.mp4")
        let viewModel = makeViewModel(
            [VoidFixtures.exercise("Test Press", sets: [])],
            repository: LateExerciseRepository(answer: old)
        )
        let pending = try #require(viewModel.videoLookupTask)

        let replacement = libraryItem("Test Row", serverId: "ex_row", video: "https://example.com/videos/row.mp4")
        viewModel.swapExercise(to: replacement)
        await pending.value

        #expect(viewModel.nativeVideoUrl == replacement.videoUrl)
        #expect(viewModel.exerciseServerId == "ex_row")
        #expect(viewModel.isResolvingVideo == false)
    }
}

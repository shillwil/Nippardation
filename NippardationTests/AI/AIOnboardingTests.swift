//
//  AIOnboardingTests.swift
//  NippardationTests
//
//  A new account's first plan: Today offers Create Workout instead of Start, the AI wizard
//  explains each split, and saving the generated plan makes it the active one.
//

import Testing
import Foundation
@testable import Nippardation

@Suite("AI onboarding")
@MainActor
struct AIOnboardingTests {

    // MARK: - Split explanations

    @Test("Offers Upper/Lower, Full Body and Bro Split, each with an explanation")
    func splitSuggestionsAreExplained() {
        let splits = AISplitSuggestion.allCases
        #expect(splits.contains(.upperLower))
        #expect(splits.contains(.fullBody))
        #expect(splits.contains(.broSplit))

        for split in splits {
            #expect(!split.displayName.isEmpty)
            #expect(!split.subtitle.isEmpty)
            #expect(!split.icon.isEmpty)
        }
        #expect(AISplitSuggestion.broSplit.subtitle.contains("One muscle group a day"))
    }

    // MARK: - Today mode

    private func overrideStore(_ name: String) -> TodayOverrideStore {
        let store = TodayOverrideStore(
            defaults: UserDefaults(suiteName: "test.onboarding.\(name)") ?? .standard,
            userIdProvider: { "test" }
        )
        store.clear()
        return store
    }

    @Test("No plans at all is the new-user state")
    func noPlansIsNewUser() {
        let viewModel = TodayViewModel.preview(program: nil, store: overrideStore("new"), hasSavedPlans: false)
        #expect(viewModel.mode == .newUser)
    }

    @Test("Saved plans but none active stays the plain empty state")
    func savedPlansWithoutActiveIsEmpty() {
        let viewModel = TodayViewModel.preview(program: nil, store: overrideStore("empty"), hasSavedPlans: true)
        #expect(viewModel.mode == .empty)
    }

    @Test("An active plan is never the new-user state")
    func activePlanIsScheduled() {
        let viewModel = TodayViewModel.preview(
            program: MockData.activeProgram,
            store: overrideStore("active"),
            hasSavedPlans: false
        )
        #expect(viewModel.mode == .scheduled)
    }

    // MARK: - Save activates

    private func makePreviewViewModel(
        program: Program,
        repository: MockProgramRepository,
        activatesOnSave: Bool
    ) -> GeneratedProgramPreviewViewModel {
        GeneratedProgramPreviewViewModel(
            program: program,
            metadata: nil,
            activatesOnSave: activatesOnSave,
            programRepository: repository,
            templateRepository: MockTemplateRepository(),
            exerciseLibraryResolver: ExerciseLibraryResolver(
                coreDataManager: CoreDataTestHelper.createInMemoryManager(),
                exerciseAPIService: nil,
                maxConcurrentLookups: 1
            )
        )
    }

    /// Waits for the save Task to finish (it reports through published flags).
    private func waitForSave(_ viewModel: GeneratedProgramPreviewViewModel) async {
        for _ in 0..<200 where !viewModel.savedSuccessfully && viewModel.error == nil {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("Saving a first plan makes it the active plan")
    func saveActivatesFirstPlan() async throws {
        let repository = MockProgramRepository()
        let program = CoreDataTestHelper.createSampleProgram(serverId: "ai-first-plan", name: "First Plan")
        let viewModel = makePreviewViewModel(program: program, repository: repository, activatesOnSave: true)

        viewModel.save()
        await waitForSave(viewModel)

        #expect(viewModel.savedSuccessfully)
        let active = try await repository.getActiveProgram()
        #expect(active?.serverId == "ai-first-plan")
    }

    @Test("Saving without activation leaves the active plan alone")
    func saveWithoutActivationKeepsActivePlan() async throws {
        let repository = MockProgramRepository()
        let before = try await repository.getActiveProgram()
        let program = CoreDataTestHelper.createSampleProgram(serverId: "ai-extra-plan", name: "Extra Plan")
        let viewModel = makePreviewViewModel(program: program, repository: repository, activatesOnSave: false)

        viewModel.save()
        await waitForSave(viewModel)

        #expect(viewModel.savedSuccessfully)
        let after = try await repository.getActiveProgram()
        #expect(after?.serverId == before?.serverId)
        #expect(after?.serverId != "ai-extra-plan")
    }
}

//
//  ExercisePickerOrderTests.swift
//  NippardationTests
//
//  Add exercises (multi-select): "Add (n)" hands the picked exercises over in the order they
//  were picked, with preselected exercises taking their place as they load, not in the
//  arbitrary order of the view model's id → exercise map.
//

import Testing
import Foundation
@testable import Nippardation

@Suite("Exercise picker order")
@MainActor
struct ExercisePickerOrderTests {

    /// Eight library exercises, "ex_0" … "ex_7": enough that a hash order matching the pick
    /// order by chance is vanishingly rare.
    private let library = (0..<8).map { VoidFixtures.libraryItem("Exercise \($0)", serverId: "ex_\($0)") }

    private func makePicker(maxSelections: Int? = nil, preselected: Set<String> = []) -> ExerciseBrowserViewModel {
        ExerciseBrowserViewModel(
            isPickerMode: true,
            maxSelections: maxSelections,
            preselectedExerciseIds: preselected,
            exerciseRepository: MockExerciseRepository()
        )
    }

    private func pickedIds(_ picker: ExerciseBrowserViewModel) -> [String] {
        picker.selectedExercisesList.map(\.serverId)
    }

    /// Waits for the library load the picker started; the mock repository answers at once.
    private func waitForLoad(_ picker: ExerciseBrowserViewModel) async throws {
        var polls = 0
        while picker.isLoading && polls < 500 {
            try await Task.sleep(nanoseconds: 10_000_000)
            polls += 1
        }
        #expect(picker.isLoading == false)
    }

    @Test func addsExercisesInTheOrderTheyWerePicked() {
        let picker = makePicker()
        let order = [5, 2, 7, 0, 3, 6, 1, 4]

        for index in order {
            picker.toggleSelection(library[index])
        }

        #expect(pickedIds(picker) == order.map { "ex_\($0)" })
    }

    @Test func deselectingDropsAnExerciseAndPickingItAgainPutsItLast() {
        let picker = makePicker()
        for index in [3, 1, 4] {
            picker.toggleSelection(library[index])
        }

        picker.toggleSelection(library[3])
        #expect(pickedIds(picker) == ["ex_1", "ex_4"])
        #expect(picker.isSelected(library[3]) == false)

        picker.toggleSelection(library[3])
        #expect(pickedIds(picker) == ["ex_1", "ex_4", "ex_3"])
    }

    @Test func aPickPastTheLimitLeavesTheOrderAlone() {
        let picker = makePicker(maxSelections: 2)
        for index in [6, 2, 5] {
            picker.toggleSelection(library[index])
        }

        #expect(pickedIds(picker) == ["ex_6", "ex_2"])
        #expect(picker.isSelected(library[5]) == false)
    }

    /// Preselected exercises join the order in library order as they load, ahead of later
    /// picks; a reload neither repeats them nor brings back one that was deselected.
    @Test func preselectedExercisesTakeTheirPlaceWhenTheyLoad() async throws {
        let picker = makePicker(preselected: ["ex_003", "ex_001"])
        #expect(pickedIds(picker).isEmpty)

        picker.loadExercises()
        try await waitForLoad(picker)
        #expect(pickedIds(picker) == ["ex_001", "ex_003"])

        let second = try #require(picker.exercises.first { $0.serverId == "ex_002" })
        let first = try #require(picker.exercises.first { $0.serverId == "ex_001" })
        picker.toggleSelection(second)
        picker.toggleSelection(first)
        #expect(pickedIds(picker) == ["ex_003", "ex_002"])

        picker.loadExercises(refresh: true)
        try await waitForLoad(picker)
        #expect(pickedIds(picker) == ["ex_003", "ex_002"])
        #expect(picker.selectedExercises == ["ex_003", "ex_002"])
    }
}

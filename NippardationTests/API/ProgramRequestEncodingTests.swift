//
//  ProgramRequestEncodingTests.swift
//  NippardationTests
//
//  Tests for the JSON the program request types put on the wire
//

import Testing
import Foundation
@testable import Nippardation

@Suite("Program request encoding")
struct ProgramRequestEncodingTests {

    // MARK: - Helpers

    /// Encodes with the same encoder the API services use and returns the top-level object.
    private func jsonObject(_ request: UpdateProgramRequest) throws -> [String: Any]? {
        let data = try JSONEncoder.apiEncoder.encode(request)
        let object = try JSONSerialization.jsonObject(with: data)
        return object as? [String: Any]
    }

    // MARK: - UpdateProgramRequest

    @Test("A metadata-only update leaves out every nil field")
    func testUpdateRequestOmitsNilFields() throws {
        guard let json = try jsonObject(UpdateProgramRequest(name: "Plan", daysPerWeek: 3)) else {
            Issue.record("Request did not encode to a JSON object")
            return
        }

        // The server rejects unknown keys and reads an absent key as "leave unchanged",
        // so nothing may be sent for the fields that were not set.
        #expect(Set(json.keys) == Set(["name", "daysPerWeek"]))
        #expect(json["name"] as? String == "Plan")
        #expect(json["daysPerWeek"] as? Int == 3)
    }

    @Test("An update can carry the whole rotation next to the day count")
    func testUpdateRequestEncodesWorkouts() throws {
        let request = UpdateProgramRequest(
            name: "Push / Pull / Legs",
            daysPerWeek: 2,
            workouts: [
                ProgramWorkoutInput(dayNumber: 0, dayLabel: nil, templateId: "tmpl_001"),
                ProgramWorkoutInput(dayNumber: 1, dayLabel: "Pull", templateId: "tmpl_002")
            ]
        )

        guard let json = try jsonObject(request) else {
            Issue.record("Request did not encode to a JSON object")
            return
        }

        #expect(Set(json.keys) == Set(["name", "daysPerWeek", "workouts"]))
        #expect(json["daysPerWeek"] as? Int == 2)

        guard let workouts = json["workouts"] as? [[String: Any]], workouts.count == 2 else {
            Issue.record("workouts did not encode to an array of two objects")
            return
        }

        // A nil day label is left out, exactly as in a create request.
        #expect(Set(workouts[0].keys) == Set(["dayNumber", "templateId"]))
        #expect(workouts[0]["dayNumber"] as? Int == 0)
        #expect(workouts[0]["templateId"] as? String == "tmpl_001")

        #expect(Set(workouts[1].keys) == Set(["dayNumber", "dayLabel", "templateId"]))
        #expect(workouts[1]["dayNumber"] as? Int == 1)
        #expect(workouts[1]["dayLabel"] as? String == "Pull")
        #expect(workouts[1]["templateId"] as? String == "tmpl_002")
    }
}

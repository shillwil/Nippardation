//
//  Exercise.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import Foundation

struct Exercise: Identifiable, Codable {
    var id = UUID()
    var type: ExerciseType
    var example: String
    var lastSetIntensityTechnique: String
    var warmUpSets: Int
    var workingSets: Int
    var reps: ClosedRange<Int>
    var rest: ClosedRange<Int>

    enum CodingKeys: String, CodingKey {
        case id, type, example, lastSetIntensityTechnique, warmUpSets, workingSets
        case repsLower, repsUpper, restLower, restUpper
    }

    init(type: ExerciseType, example: String, lastSetIntensityTechnique: String, warmUpSets: Int, workingSets: Int, reps: ClosedRange<Int>, rest: ClosedRange<Int>) {
        self.type = type
        self.example = example
        self.lastSetIntensityTechnique = lastSetIntensityTechnique
        self.warmUpSets = warmUpSets
        self.workingSets = workingSets
        self.reps = reps
        self.rest = rest
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(ExerciseType.self, forKey: .type)
        example = try container.decode(String.self, forKey: .example)
        lastSetIntensityTechnique = try container.decode(String.self, forKey: .lastSetIntensityTechnique)
        warmUpSets = try container.decode(Int.self, forKey: .warmUpSets)
        workingSets = try container.decode(Int.self, forKey: .workingSets)
        let repsLower = try container.decode(Int.self, forKey: .repsLower)
        let repsUpper = try container.decode(Int.self, forKey: .repsUpper)
        reps = repsLower...repsUpper
        let restLower = try container.decode(Int.self, forKey: .restLower)
        let restUpper = try container.decode(Int.self, forKey: .restUpper)
        rest = restLower...restUpper
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(example, forKey: .example)
        try container.encode(lastSetIntensityTechnique, forKey: .lastSetIntensityTechnique)
        try container.encode(warmUpSets, forKey: .warmUpSets)
        try container.encode(workingSets, forKey: .workingSets)
        try container.encode(reps.lowerBound, forKey: .repsLower)
        try container.encode(reps.upperBound, forKey: .repsUpper)
        try container.encode(rest.lowerBound, forKey: .restLower)
        try container.encode(rest.upperBound, forKey: .restUpper)
    }
}

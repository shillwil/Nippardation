//
//  TrackedSet.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import Foundation

struct TrackedSet: Hashable, Equatable, Identifiable {
    let id = UUID()
    var reps: Int
    var weight: Double  // Weight in lbs
    var setType: SetType
    var exerciseType: ExerciseType
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(reps)
        hasher.combine(weight)
        hasher.combine(exerciseType)
    }
        
    static func == (lhs: TrackedSet, rhs: TrackedSet) -> Bool {
        return lhs.id == rhs.id &&
               lhs.reps == rhs.reps &&
               lhs.weight == rhs.weight &&
               lhs.exerciseType == rhs.exerciseType
    }
}

enum SetType: String, Codable {
    case warmup
    case working
}

// Extension to make TrackedSet Codable
extension TrackedSet: Codable {
    enum CodingKeys: String, CodingKey {
        case reps, weight, exerciseTypeName, exerciseTypeMuscleGroups, setType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reps = try container.decode(Int.self, forKey: .reps)
        weight = try container.decode(Double.self, forKey: .weight)
        
        let typeName = try container.decode(String.self, forKey: .exerciseTypeName)
        let muscleGroups = try container.decode([MuscleGroup].self, forKey: .exerciseTypeMuscleGroups)
        
        exerciseType = ExerciseType(name: typeName, muscleGroup: muscleGroups)
        
        setType = try container.decode(SetType.self, forKey: .setType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reps, forKey: .reps)
        try container.encode(weight, forKey: .weight)
        try container.encode(exerciseType.name, forKey: .exerciseTypeName)
        try container.encode(exerciseType.muscleGroup, forKey: .exerciseTypeMuscleGroups)
        try container.encode(setType, forKey: .setType)
    }
}

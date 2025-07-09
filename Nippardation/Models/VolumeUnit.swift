//
//  VolumeUnit.swift
//  Nippardation
//
//  Created by Claude on 7/8/25.
//

import Foundation

enum VolumeUnit: String, CaseIterable {
    case pounds = "lbs"
    case kilograms = "kg"
    case pyramidBlocks = "Pyramid Blocks"
    
    func convert(_ value: Double, from unit: VolumeUnit) -> Double {
        let pounds: Double
        
        switch unit {
        case .pounds:
            pounds = value
        case .kilograms:
            pounds = value * 2.20462
        case .pyramidBlocks:
            pounds = value * 5000
        }
        
        switch self {
        case .pounds:
            return pounds
        case .kilograms:
            return pounds / 2.20462
        case .pyramidBlocks:
            return pounds / 5000
        }
    }
    
    func format(_ value: Double) -> String {
        switch self {
        case .pounds, .kilograms:
            return "\(Int(value)) \(rawValue)"
        case .pyramidBlocks:
            let formattedValue: String
            if value < 1 {
                formattedValue = "<1"
            } else if value.truncatingRemainder(dividingBy: 1) == 0 {
                formattedValue = "\(Int(value))"
            } else {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = 1
                formatter.maximumFractionDigits = 2
                formattedValue = formatter.string(from: NSNumber(value: value)) ?? "0"
            }
            let unit = value < 1 ? "Pyramid Block" : "Pyramid Blocks"
            return "\(formattedValue) \(unit)"
        }
    }
    
    func formatWithNewline(_ value: Double) -> String {
        switch self {
        case .pounds, .kilograms:
            return "\(Int(value)) \(rawValue)"
        case .pyramidBlocks:
            let formattedValue: String
            if value < 1 {
                formattedValue = "<1"
            } else if value.truncatingRemainder(dividingBy: 1) == 0 {
                formattedValue = "\(Int(value))"
            } else {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = 1
                formatter.maximumFractionDigits = 2
                formattedValue = formatter.string(from: NSNumber(value: value)) ?? "0"
            }
            let unit = value < 1 ? "Pyramid Block" : "Pyramid Blocks"
            return "\(formattedValue)\n\(unit)"
        }
    }
    
    func next() -> VolumeUnit {
        let allCases = VolumeUnit.allCases
        guard let currentIndex = allCases.firstIndex(of: self) else { return .pounds }
        let nextIndex = (currentIndex + 1) % allCases.count
        return allCases[nextIndex]
    }
}

//
//  AIGenerationStatus.swift
//  Nippardation
//
//  Domain model for AI generation quota information
//

import Foundation

/// Represents the user's AI generation quota status
struct AIGenerationStatus {
    let generationsUsed: Int
    let generationsRemaining: Int
    let generationsLimit: Int
    let resetsAt: Date
    let tier: String

    /// Human-readable reset date
    var resetsAtFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: resetsAt)
    }

    /// Whether the user has generations remaining
    var hasRemaining: Bool {
        generationsRemaining > 0
    }

    /// Maps from API response DTO
    static func from(_ dto: GenerationStatusResponse) -> AIGenerationStatus {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var resetDate = formatter.date(from: dto.resetsAt) ?? Date()
        if resetDate == Date() {
            formatter.formatOptions = [.withInternetDateTime]
            resetDate = formatter.date(from: dto.resetsAt) ?? Date()
        }

        return AIGenerationStatus(
            generationsUsed: dto.generationsUsed,
            generationsRemaining: dto.generationsRemaining,
            generationsLimit: dto.generationsLimit,
            resetsAt: resetDate,
            tier: dto.tier
        )
    }
}

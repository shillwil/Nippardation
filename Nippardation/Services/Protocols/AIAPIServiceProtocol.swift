//
//  AIAPIServiceProtocol.swift
//  Nippardation
//
//  Protocol for AI generation API operations
//

import Foundation

/// Protocol for AI-powered program generation API operations
protocol AIAPIServiceProtocol: Sendable {

    /// Generate a complete workout program using AI
    /// - Parameter request: Generation parameters (goal, schedule, equipment, etc.)
    /// - Returns: Generated program with generation metadata
    func generateProgram(_ request: GenerateProgramRequest) async throws -> GenerateProgramResponse

    /// Check the user's remaining generation quota
    /// - Returns: Quota status including remaining generations and reset date
    func fetchGenerationStatus() async throws -> GenerationStatusResponse

    /// Save or update the user's strength profile
    /// - Parameter request: Strength data entries to save
    func saveStrengthProfile(_ request: StrengthProfileRequest) async throws

    /// Load the user's saved strength profile
    /// - Returns: Stored strength profile with matched exercise IDs
    func fetchStrengthProfile() async throws -> StrengthProfileResponse
}

//
//  UserAPIServiceProtocol.swift
//  Nippardation
//
//  Phase 0 Extension: Protocol for user/auth API operations
//
//  Implemented by: Agent A (UserAPIService)
//  Used by: AuthManager, ProfileViewModel
//

import Foundation

/// Protocol for user/auth API operations
///
/// This protocol defines the contract for user authentication and profile
/// management, enabling parallel development.
protocol UserAPIServiceProtocol: Sendable {

    /// Authenticate with the backend using Firebase token
    /// - Returns: User DTO (creates user on first login)
    /// - Throws: RepositoryError.unauthorized if token is invalid
    /// - Note: Firebase token is automatically attached via NetworkManager
    func login() async throws -> UserDTO

    /// Fetch the current user's profile
    /// - Returns: User DTO with full profile data
    func fetchProfile() async throws -> UserDTO

    /// Update the current user's profile
    /// - Parameter request: Update request with fields to change
    /// - Returns: Updated user DTO
    func updateProfile(_ request: UpdateUserRequest) async throws -> UserDTO
}

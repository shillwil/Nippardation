//
//  SyncAPIServiceProtocol.swift
//  Nippardation
//
//  Phase 0 Extension: Protocol for sync API operations
//
//  Implemented by: Agent A (SyncAPIService)
//  Used by: Agent B (SyncService)
//

import Foundation

/// Protocol for sync API operations
///
/// This protocol defines the contract between the API service layer (Agent A)
/// and the sync service layer (Agent B), enabling parallel development.
protocol SyncAPIServiceProtocol: Sendable {

    /// Sync workout data with the server
    /// - Parameter payload: Sync request containing device info and workouts
    /// - Returns: Sync response with results, conflicts, and server data
    /// - Throws: RepositoryError on network or server failure
    ///
    /// The sync process:
    /// 1. Upload local changes (workouts since last sync)
    /// 2. Download server changes (workouts from other devices)
    /// 3. Resolve conflicts using timestamp-based resolution (newer wins)
    /// 4. Return unified result
    func sync(payload: SyncRequestDTO) async throws -> SyncResponseDTO
}

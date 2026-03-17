//
//  ShareAPIServiceProtocol.swift
//  Nippardation
//
//  Protocol for share API operations
//

import Foundation

/// Protocol for sharing programs and templates via shareable links
protocol ShareAPIServiceProtocol: Sendable {

    /// Create a new share for a program or template
    /// - Parameters:
    ///   - type: The item type ("program" or "template")
    ///   - itemId: The server ID of the item to share
    /// - Returns: Share creation response with token and URL
    func createShare(type: String, itemId: String) async throws -> ShareCreateResponse

    /// Fetch share details for previewing before import
    /// - Parameter token: The share token from the URL
    /// - Returns: Full share details including the shared item snapshot
    func fetchShare(token: String) async throws -> ShareDetailResponse
}

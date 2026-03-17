//
//  ShareDTO.swift
//  Nippardation
//
//  API Data Transfer Objects for sharing programs and templates
//

import Foundation

// MARK: - Request DTOs

/// Request body for POST /api/shares
struct ShareCreateRequest: Codable {
    let type: String
    let itemId: String
}

// MARK: - Response DTOs

/// Response from POST /api/shares
struct ShareCreateResponse: Codable {
    let token: String
    let shareUrl: String
    let expiresAt: String?
}

/// Response from GET /api/shares/{token}
struct ShareDetailResponse: Codable {
    let token: String
    let type: String
    let sharedBy: SharedByDTO
    let sharedAt: String
    let expiresAt: String?
    let template: TemplateDTO?
    let program: ProgramDTO?
}

/// Information about the user who shared the item
struct SharedByDTO: Codable {
    let handle: String
    let displayName: String?
    let avatarUrl: String?
}

//
//  SharedItem.swift
//  Nippardation
//
//  Domain model for shared programs and templates
//

import Foundation

/// The type of shared item
enum ShareType: String {
    case program
    case template
}

/// Domain model representing a shared item received via a share link
struct SharedItem {
    let token: String
    let type: ShareType
    let sharedBy: SharedBy
    let sharedAt: Date
    let template: Template?
    let program: Program?

    struct SharedBy {
        let handle: String
        let displayName: String?
        let avatarUrl: String?
    }
}

// MARK: - Mapping from DTO

extension SharedItem {
    /// Creates a SharedItem from a ShareDetailResponse DTO
    static func fromDTO(_ dto: ShareDetailResponse) -> SharedItem {
        let type = ShareType(rawValue: dto.type) ?? .template

        let sharedBy = SharedBy(
            handle: dto.sharedBy.handle,
            displayName: dto.sharedBy.displayName,
            avatarUrl: dto.sharedBy.avatarUrl
        )

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var sharedAt = formatter.date(from: dto.sharedAt)
        if sharedAt == nil {
            formatter.formatOptions = [.withInternetDateTime]
            sharedAt = formatter.date(from: dto.sharedAt)
        }

        return SharedItem(
            token: dto.token,
            type: type,
            sharedBy: sharedBy,
            sharedAt: sharedAt ?? Date(),
            template: dto.template.map { TemplateMapper.toDomain($0) },
            program: dto.program.map { ProgramMapper.toDomain($0) }
        )
    }
}

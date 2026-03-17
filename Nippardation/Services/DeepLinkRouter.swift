//
//  DeepLinkRouter.swift
//  Nippardation
//
//  Parses nippardation:// URLs and manages pending share state
//

import Foundation
import Combine

private let deepLinkScheme = "nippardation"
private let deepLinkShareHost = "share"

/// Singleton that handles incoming deep links and exposes pending share tokens
@MainActor
final class DeepLinkRouter: ObservableObject {

    static let shared = DeepLinkRouter()

    /// The pending share token from an incoming URL, cleared after consumption
    @Published var pendingShareToken: String?

    private init() {}

    /// Handles an incoming URL and extracts the share token if valid
    /// - Parameter url: The URL received via onOpenURL
    /// - Returns: true if the URL was handled
    @discardableResult
    func handleURL(_ url: URL) -> Bool {
        guard let token = DeepLinkRouter.extractShareToken(from: url) else {
            return false
        }

        pendingShareToken = token
        return true
    }

    /// Clears the pending share token
    func clearPendingToken() {
        pendingShareToken = nil
    }

    /// Extracts a share token from a nippardation://share/TOKEN URL
    /// - Parameter url: The URL to parse
    /// - Returns: The token string, or nil if the URL is invalid
    nonisolated static func extractShareToken(from url: URL) -> String? {
        guard url.scheme == deepLinkScheme else { return nil }

        // Handle both nippardation://share/TOKEN and nippardation:///share/TOKEN
        let host = url.host()
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        // Case 1: nippardation://share/TOKEN (host = "share", path = "/TOKEN")
        if host == deepLinkShareHost, let token = pathComponents.first, !token.isEmpty {
            return token
        }

        // Case 2: nippardation:///share/TOKEN (no host, path = "/share/TOKEN")
        if host == nil || host?.isEmpty == true {
            if pathComponents.count >= 2, pathComponents[0] == deepLinkShareHost {
                let token = pathComponents[1]
                return token.isEmpty ? nil : token
            }
        }

        return nil
    }
}

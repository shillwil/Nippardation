//
//  DeepLinkRouter.swift
//  Nippardation
//
//  Parses incoming share links and exposes the pending share token.
//  Accepted forms:
//    nippardation://share/<token>      (what the backend issues today)
//    recess://plan/<token>             (Void spec)
//    recess://share/<token>
//    https://recess.fit/p/<token>      (universal link; needs the associated-domains entitlement to open the app)
//

import Foundation
import Combine

private let legacyScheme = "nippardation"
private let recessScheme = "recess"
private let shareHosts: Set<String> = ["share", "plan"]
private let universalHost = "recess.fit"
private let universalPathPrefix = "p"

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

    /// Opens a token directly (e.g. tapping a row under Sent to you).
    func open(token: String) {
        pendingShareToken = token
    }

    /// Clears the pending share token
    func clearPendingToken() {
        pendingShareToken = nil
    }

    /// Whether a pasted string is a share link we understand.
    nonisolated static func isShareLink(_ text: String) -> Bool {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return extractShareToken(from: url) != nil
    }

    /// Extracts a share token from any supported link form.
    /// - Parameter url: The URL to parse
    /// - Returns: The token string, or nil if the URL is invalid
    nonisolated static func extractShareToken(from url: URL) -> String? {
        let scheme = url.scheme?.lowercased()
        let host = url.host()?.lowercased()
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch scheme {
        case legacyScheme, recessScheme:
            // scheme://share/TOKEN or scheme://plan/TOKEN (host = "share"/"plan", path = "/TOKEN")
            if let host, shareHosts.contains(host) {
                guard let token = pathComponents.first, !token.isEmpty else { return nil }
                return token
            }
            // scheme:///share/TOKEN (no host, path = "/share/TOKEN")
            if host == nil || host?.isEmpty == true {
                if pathComponents.count >= 2, shareHosts.contains(pathComponents[0]) {
                    let token = pathComponents[1]
                    return token.isEmpty ? nil : token
                }
            }
            return nil

        case "https", "http":
            // https://recess.fit/p/TOKEN (also www.recess.fit)
            guard let host, host == universalHost || host == "www.\(universalHost)" else { return nil }
            guard pathComponents.count >= 2, pathComponents[0] == universalPathPrefix else { return nil }
            let token = pathComponents[1]
            return token.isEmpty ? nil : token

        default:
            return nil
        }
    }
}

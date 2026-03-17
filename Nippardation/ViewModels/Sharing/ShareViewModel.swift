//
//  ShareViewModel.swift
//  Nippardation
//
//  ViewModel for creating share links (outbound sharing)
//

import Foundation

@MainActor
final class ShareViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var shareURL: URL?
    @Published var error: String?

    private let shareAPIService: any ShareAPIServiceProtocol

    init(shareAPIService: (any ShareAPIServiceProtocol)? = nil) {
        self.shareAPIService = shareAPIService ?? DependencyContainer.shared.shareAPIService
    }

    /// Creates a share link for a program or template
    /// - Parameters:
    ///   - type: "program" or "template"
    ///   - itemId: The server ID of the item to share
    func createShare(type: String, itemId: String) {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        shareURL = nil

        Task {
            do {
                let response = try await shareAPIService.createShare(type: type, itemId: itemId)
                self.shareURL = URL(string: response.shareUrl)
                self.isLoading = false
            } catch let repoError as RepositoryError {
                self.error = repoError.errorDescription ?? "Failed to create share link"
                self.isLoading = false
            } catch {
                self.error = "Failed to create share link"
                self.isLoading = false
            }
        }
    }

    func clearError() {
        error = nil
    }
}

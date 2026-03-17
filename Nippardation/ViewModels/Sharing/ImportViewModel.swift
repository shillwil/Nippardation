//
//  ImportViewModel.swift
//  Nippardation
//
//  ViewModel for importing shared programs and templates (inbound sharing)
//

import Foundation

@MainActor
final class ImportViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded
        case importing
        case imported
        case error(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.loaded, .loaded),
                 (.importing, .importing), (.imported, .imported):
                return true
            case (.error(let a), .error(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    @Published var state: State = .idle
    @Published var sharedItem: SharedItem?

    private let shareAPIService: any ShareAPIServiceProtocol
    private let templateRepository: any TemplateRepositoryProtocol
    private let programRepository: any ProgramRepositoryProtocol
    private var token: String?

    init(
        shareAPIService: (any ShareAPIServiceProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil,
        programRepository: (any ProgramRepositoryProtocol)? = nil
    ) {
        self.shareAPIService = shareAPIService ?? DependencyContainer.shared.shareAPIService
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
    }

    /// Fetches the share preview from the backend
    func fetchShare(token: String) {
        self.token = token
        state = .loading
        sharedItem = nil

        Task {
            do {
                let response = try await shareAPIService.fetchShare(token: token)
                self.sharedItem = SharedItem.fromDTO(response)
                self.state = .loaded
            } catch let error as RepositoryError {
                if case .notFound = error {
                    self.state = .error("This share link is invalid or has expired.")
                } else {
                    self.state = .error(error.errorDescription ?? "Failed to load shared item")
                }
            } catch {
                self.state = .error("Failed to load shared item")
            }
        }
    }

    /// Retries fetching the share preview
    func retry() {
        guard let token = token else { return }
        fetchShare(token: token)
    }

    /// Imports the shared item into the user's library
    func importItem() {
        guard let item = sharedItem else { return }
        state = .importing

        Task {
            do {
                switch item.type {
                case .template:
                    guard let template = item.template else {
                        self.state = .error("No template data found")
                        return
                    }
                    _ = try await templateRepository.createTemplate(template)

                case .program:
                    guard let program = item.program else {
                        self.state = .error("No program data found")
                        return
                    }
                    // For programs, first import all templates, then create the program
                    // The backend snapshot includes full template data in the program workouts
                    for workout in program.workouts {
                        if let template = workout.template {
                            _ = try await templateRepository.createTemplate(template)
                        }
                    }
                    _ = try await programRepository.createProgram(program)
                }

                self.state = .imported
            } catch let error as RepositoryError {
                self.state = .error(error.errorDescription ?? "Failed to import")
            } catch {
                self.state = .error("Failed to import")
            }
        }
    }
}

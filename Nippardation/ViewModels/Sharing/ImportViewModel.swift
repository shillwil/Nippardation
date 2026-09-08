//
//  ImportViewModel.swift
//  Nippardation
//
//  ViewModel for importing shared programs and templates (inbound sharing)
//

import Foundation

/// What an import produced.
enum ImportResult {
    case template(Template)
    case program(Program)
}

/// Import-specific failures (missing payloads in a share).
enum ImportError: LocalizedError {
    case missingTemplate
    case missingProgram

    var errorDescription: String? {
        switch self {
        case .missingTemplate: return "No workout data found"
        case .missingProgram: return "No plan data found"
        }
    }
}

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
    private let exerciseLibraryResolver: ExerciseLibraryResolver
    private var token: String?

    init(
        shareAPIService: (any ShareAPIServiceProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil,
        programRepository: (any ProgramRepositoryProtocol)? = nil,
        exerciseLibraryResolver: ExerciseLibraryResolver? = nil
    ) {
        self.shareAPIService = shareAPIService ?? DependencyContainer.shared.shareAPIService
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
        self.exerciseLibraryResolver = exerciseLibraryResolver ?? DependencyContainer.shared.exerciseLibraryResolver
    }

    /// Fetches the share preview from the backend
    func fetchShare(token: String) {
        self.token = token
        state = .loading
        sharedItem = nil

        Task {
            do {
                let response = try await shareAPIService.fetchShare(token: token)
                // Share payloads embed templates without the nested exercise object, so the
                // preview would otherwise read "Exercise" on every row.
                self.sharedItem = await exerciseLibraryResolver.resolve(SharedItem.fromDTO(response))
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
                _ = try await performImport(item)
                self.state = .imported
            } catch let error as ImportError {
                self.state = .error(error.errorDescription ?? "Failed to import")
            } catch let error as RepositoryError {
                self.state = .error(error.errorDescription ?? "Failed to import")
            } catch {
                self.state = .error("Failed to import")
            }
        }
    }

    // MARK: - Import core

    /// Copies a shared item into the user's library and returns what was created.
    /// Programs get every embedded template created first; workout references are then
    /// remapped to the new template ids before the program itself is created.
    func performImport(_ item: SharedItem) async throws -> ImportResult {
        switch item.type {
        case .template:
            guard let template = item.template else { throw ImportError.missingTemplate }
            let created = try await templateRepository.createTemplate(template)
            return .template(created)

        case .program:
            guard let program = item.program else { throw ImportError.missingProgram }
            let created = try await Self.importProgram(
                program,
                templateRepository: templateRepository,
                programRepository: programRepository
            )
            return .program(created)
        }
    }

    /// Shared remap logic: create templates, remap ids, create the program.
    static func importProgram(
        _ program: Program,
        templateRepository: any TemplateRepositoryProtocol,
        programRepository: any ProgramRepositoryProtocol
    ) async throws -> Program {
        // Import all templates first and build a mapping of old → new server IDs.
        // The backend assigns new IDs to imported templates, so the program's
        // workout references must be updated before creating the program.
        var templateIdMap: [String: String] = [:]
        for workout in program.workouts {
            if let template = workout.template, templateIdMap[template.serverId] == nil {
                let created = try await templateRepository.createTemplate(template)
                templateIdMap[template.serverId] = created.serverId
            }
        }

        // Rebuild workouts with the new template server IDs
        let remappedWorkouts = program.workouts.map { workout in
            ProgramWorkout(
                id: UUID(),
                serverId: "",
                dayNumber: workout.dayNumber,
                dayLabel: workout.dayLabel,
                templateServerId: templateIdMap[workout.templateServerId] ?? workout.templateServerId,
                template: workout.template
            )
        }

        var updatedProgram = program
        updatedProgram.workouts = remappedWorkouts
        return try await programRepository.createProgram(updatedProgram)
    }
}

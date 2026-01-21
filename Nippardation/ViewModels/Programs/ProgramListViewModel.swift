//
//  ProgramListViewModel.swift
//  Nippardation
//
//  ViewModel for managing the list of workout programs
//

import Foundation
import Combine

@MainActor
final class ProgramListViewModel: ObservableObject {

    // MARK: - Published State

    @Published var programs: [Program] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage = 1
    @Published var hasMore = false

    // MARK: - Dependencies

    private let programRepository: any ProgramRepositoryProtocol
    private let taskManager = TaskManager()

    // MARK: - Initialization

    init(programRepository: (any ProgramRepositoryProtocol)? = nil) {
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
    }

    // MARK: - Public Methods

    /// Loads programs from the repository
    /// - Parameter refresh: If true, reloads from the beginning
    func loadPrograms(refresh: Bool = false) {
        if refresh {
            currentPage = 1
            programs = []
        }

        guard !isLoading else { return }

        Task {
            await taskManager.run(id: "loadPrograms") { [weak self] in
                guard let self = self else { return }

                await MainActor.run { self.isLoading = true }

                do {
                    let fetchedPrograms = try await self.programRepository.fetchPrograms(forceRefresh: refresh)

                    await MainActor.run {
                        self.programs = fetchedPrograms
                        self.hasMore = false // fetchPrograms returns all user's programs
                        self.error = nil
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        // Try loading from cache on failure
                        let cached = self.programRepository.getCachedPrograms()
                        if !cached.isEmpty {
                            self.programs = cached
                        }
                        self.error = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
    }

    /// Loads public programs with pagination
    /// - Parameter refresh: If true, reloads from the beginning
    func loadPublicPrograms(refresh: Bool = false) {
        if refresh {
            currentPage = 1
            programs = []
        }

        guard !isLoading else { return }

        Task {
            await taskManager.run(id: "loadPublicPrograms") { [weak self] in
                guard let self = self else { return }

                await MainActor.run { self.isLoading = true }

                do {
                    let result = try await self.programRepository.fetchPublicPrograms(
                        page: self.currentPage,
                        category: nil
                    )

                    await MainActor.run {
                        if refresh {
                            self.programs = result.items
                        } else {
                            self.programs.append(contentsOf: result.items)
                        }
                        self.currentPage = result.page
                        self.hasMore = result.hasNextPage
                        self.error = nil
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.error = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
    }

    /// Loads more public programs if available
    func loadMore() {
        guard hasMore && !isLoading else { return }
        currentPage += 1
        loadPublicPrograms()
    }

    /// Deletes a program
    /// - Parameter program: The program to delete
    func deleteProgram(_ program: Program) {
        Task {
            await taskManager.run(id: "delete-\(program.serverId)") { [weak self] in
                guard let self = self else { return }

                do {
                    try await self.programRepository.deleteProgram(serverId: program.serverId)

                    await MainActor.run {
                        self.programs.removeAll { $0.id == program.id }
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to delete program: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Activates a program, deactivating any currently active program
    /// - Parameter program: The program to activate
    func activateProgram(_ program: Program) {
        Task {
            await taskManager.run(id: "activate-\(program.serverId)") { [weak self] in
                guard let self = self else { return }

                do {
                    let updated = try await self.programRepository.setActiveProgram(serverId: program.serverId)

                    await MainActor.run {
                        // Update all programs to reflect new active state
                        self.programs = self.programs.map { p in
                            if p.id == updated.id {
                                return updated
                            } else if p.isActive {
                                // Deactivate previously active program
                                return self.deactivatedCopy(of: p)
                            }
                            return p
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to activate program: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Duplicates a program
    /// - Parameter program: The program to duplicate
    func duplicateProgram(_ program: Program) {
        Task {
            await taskManager.run(id: "duplicate-\(program.serverId)") { [weak self] in
                guard let self = self else { return }

                do {
                    let duplicate = try await self.programRepository.duplicateProgram(serverId: program.serverId)

                    await MainActor.run {
                        self.programs.insert(duplicate, at: 0)
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Failed to duplicate program: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Clears the current error message
    func clearError() {
        error = nil
    }

    // MARK: - Private Helpers

    private func deactivatedCopy(of program: Program) -> Program {
        Program(
            id: program.id,
            serverId: program.serverId,
            name: program.name,
            description: program.description,
            daysPerWeek: program.daysPerWeek,
            durationWeeks: program.durationWeeks,
            workouts: program.workouts,
            isActive: false,
            currentDayIndex: program.currentDayIndex,
            timesCompleted: program.timesCompleted,
            isPublic: program.isPublic,
            isAiGenerated: program.isAiGenerated,
            createdAt: program.createdAt,
            updatedAt: program.updatedAt,
            lastFetchedAt: program.lastFetchedAt
        )
    }
}

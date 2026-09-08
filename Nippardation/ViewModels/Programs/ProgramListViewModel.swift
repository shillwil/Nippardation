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

    // MARK: - Delete State

    @Published var programToDeleteDetail: Program?
    @Published var isFetchingDeleteDetail = false
    @Published var isDeletingProgram = false
    @Published var showTemplateDeleteSheet = false
    @Published var showSimpleDeleteAlert = false
    var programToDelete: Program?

    /// Called on the main actor after a program was activated, duplicated or deleted
    /// so the rest of the app (Today / Plan) can refresh.
    var onMutation: (() -> Void)?

    // MARK: - Dependencies

    private let programRepository: any ProgramRepositoryProtocol
    private let taskManager = TaskManager()

    // MARK: - Private State

    private var isLoadingPublicPrograms = false

    // MARK: - Initialization

    init(programRepository: (any ProgramRepositoryProtocol)? = nil) {
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
    }

    // MARK: - Public Methods

    /// Loads user's programs from the repository
    /// - Parameter refresh: If true, reloads from the beginning
    func loadPrograms(refresh: Bool = false) {
        if refresh {
            currentPage = 1
            programs = []
            // Reset loading state to allow refresh during existing load
            // taskManager.run will cancel the old task
            isLoading = false
        }

        guard !isLoading else { return }

        isLoadingPublicPrograms = false

        Task {
            await taskManager.run(id: "loadPrograms") { [weak self] in
                guard let self = self else { return }
                await self.performLoadPrograms(forceRefresh: refresh)
            }
        }
    }

    /// Loads public programs with pagination
    /// - Parameters:
    ///   - refresh: If true, reloads from the beginning
    ///   - loadingNextPage: If true, loads the next page (currentPage + 1)
    func loadPublicPrograms(refresh: Bool = false, loadingNextPage: Bool = false) {
        if refresh {
            currentPage = 1
            programs = []
            // Reset loading state to allow refresh during existing load
            // taskManager.run will cancel the old task
            isLoading = false
        }

        guard !isLoading else { return }

        isLoadingPublicPrograms = true

        // Determine which page to fetch - only increment when loading next page
        let pageToFetch = loadingNextPage ? currentPage + 1 : currentPage

        Task {
            await taskManager.run(id: "loadPublicPrograms") { [weak self] in
                guard let self = self else { return }

                await MainActor.run { self.isLoading = true }

                do {
                    let result = try await self.programRepository.fetchPublicPrograms(
                        page: pageToFetch,
                        category: nil
                    )

                    await MainActor.run {
                        if refresh {
                            self.programs = result.items
                        } else {
                            self.programs.append(contentsOf: result.items)
                        }
                        // Only update currentPage on success
                        self.currentPage = result.page
                        self.hasMore = result.hasNextPage
                        self.error = nil
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        // Don't update currentPage on error - allows retry of same page
                        self.error = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
    }

    /// Loads more programs if available (only applicable for public programs)
    func loadMore() {
        guard hasMore && !isLoading && isLoadingPublicPrograms else { return }
        // Don't increment page here - it's updated on success in loadPublicPrograms
        loadPublicPrograms(loadingNextPage: true)
    }

    /// Prepares to delete a program. For AI programs, fetches detail to show template selection.
    func prepareDeleteProgram(_ program: Program) {
        programToDelete = program
        isFetchingDeleteDetail = true

        // Always fetch detail — the list endpoint may not include isAiGenerated
        // or full workout/template data needed for the template cleanup flow.
        Task {
            await taskManager.run(id: "prepareDelete") { [weak self] in
                guard let self = self else { return }

                do {
                    let detail = try await self.programRepository.fetchProgram(
                        serverId: program.serverId,
                        forceRefresh: true
                    )

                    // The embedded template summaries in the program detail
                    // don't include isAiGenerated — so we check the program itself.
                    // The backend handles safety: only AI templates get deleted.
                    let hasTemplates = detail.workouts.contains { $0.template != nil }

                    await MainActor.run {
                        self.isFetchingDeleteDetail = false
                        if detail.isAiGenerated && hasTemplates {
                            self.programToDeleteDetail = detail
                            self.showTemplateDeleteSheet = true
                        } else {
                            self.showSimpleDeleteAlert = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.isFetchingDeleteDetail = false
                        // Fall back to simple delete on fetch failure
                        self.showSimpleDeleteAlert = true
                    }
                }
            }
        }
    }

    /// Deletes a program (simple, no template cleanup)
    func deleteProgram(_ program: Program) {
        Task {
            await taskManager.run(id: "delete-\(program.serverId)") { [weak self] in
                guard let self = self else { return }

                do {
                    try await self.programRepository.deleteProgram(serverId: program.serverId)

                    await MainActor.run {
                        self.programs.removeAll { $0.serverId == program.serverId }
                        self.onMutation?()
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Couldn't delete the plan: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Deletes an AI program with selective template cleanup
    func deleteProgramWithTemplates(keepTemplateIds: [String]) {
        guard let detail = programToDeleteDetail else { return }

        // Extract all template IDs from the program's workouts NOW (from the detail
        // we already fetched) — don't rely on reading them back from cache later.
        let allTemplateIds = Array(Set(detail.workouts.map(\.templateServerId)))

        isDeletingProgram = true

        Task {
            await taskManager.run(id: "delete-\(detail.serverId)") { [weak self] in
                guard let self = self else { return }

                do {
                    try await self.programRepository.deleteProgram(
                        serverId: detail.serverId,
                        deleteTemplates: true,
                        keepTemplateIds: keepTemplateIds,
                        programTemplateIds: allTemplateIds
                    )

                    await MainActor.run {
                        self.programs.removeAll { $0.serverId == detail.serverId }
                        self.isDeletingProgram = false
                        self.programToDelete = nil
                        self.programToDeleteDetail = nil
                        self.showTemplateDeleteSheet = false
                        self.onMutation?()
                    }
                } catch {
                    await MainActor.run {
                        self.isDeletingProgram = false
                        self.error = "Couldn't delete the plan: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    func clearDeleteState() {
        programToDelete = nil
        programToDeleteDetail = nil
        showTemplateDeleteSheet = false
        showSimpleDeleteAlert = false
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
                            if p.serverId == updated.serverId {
                                return updated
                            } else if p.isActive {
                                // Deactivate previously active program
                                return self.deactivatedCopy(of: p)
                            }
                            return p
                        }
                        self.onMutation?()
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Couldn't activate the plan: \(error.localizedDescription)"
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
                        self.onMutation?()
                    }
                } catch {
                    await MainActor.run {
                        self.error = "Couldn't duplicate the plan: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Clears the current error message
    func clearError() {
        error = nil
    }

    /// Refreshes programs (async version for pull-to-refresh)
    func refreshAsync() async {
        await withCheckedContinuation { continuation in
            Task {
                await taskManager.run(id: "loadPrograms") { [weak self] in
                    guard let self = self else {
                        continuation.resume()
                        return
                    }

                    await MainActor.run { self.currentPage = 1 }
                    await self.performLoadPrograms(forceRefresh: true)
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Private Helpers

    /// Core loading logic shared between loadPrograms and refreshAsync
    /// - Parameter forceRefresh: Whether to force refresh from network
    private func performLoadPrograms(forceRefresh: Bool) async {
        await MainActor.run { self.isLoading = true }

        do {
            let fetchedPrograms = try await programRepository.fetchPrograms(forceRefresh: forceRefresh)

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

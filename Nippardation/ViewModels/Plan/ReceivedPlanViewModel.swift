//
//  ReceivedPlanViewModel.swift
//  Nippardation
//
//  Drives the Plan received sheet: fetches a share by token, shows the day strip,
//  imports + activates on "Use this plan", or files it under Sent to you.
//

import Foundation

@MainActor
final class ReceivedPlanViewModel: ObservableObject {

    enum State: Equatable {
        case loading
        case loaded
        case importing
        case imported
        case error(String)
    }

    /// One cell of the MON…SUN strip.
    struct DayCell: Identifiable {
        let id: Int
        let label: String
        /// nil = rest day (ghost tile).
        let glyph: VoidIcon?
        let template: Template?
    }

    // MARK: - Published

    @Published private(set) var state: State = .loading
    @Published private(set) var item: SharedItem?
    @Published private(set) var plan: ReceivedPlan?
    /// True once the plan is filed under Sent to you as read (saved for later, used, or opened from the list).
    @Published private(set) var isSaved = false
    /// What "Use this plan" already created, so a retry after a failed activation only activates.
    @Published private(set) var importedProgram: Program?
    @Published private(set) var importedTemplate: Template?

    // MARK: - Dependencies

    let token: String
    private let shareAPIService: any ShareAPIServiceProtocol
    private let templateRepository: any TemplateRepositoryProtocol
    private let programRepository: any ProgramRepositoryProtocol
    private let exerciseLibraryResolver: ExerciseLibraryResolver
    private let store: ReceivedPlansStore
    private let taskManager = TaskManager()

    init(
        token: String,
        shareAPIService: (any ShareAPIServiceProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil,
        programRepository: (any ProgramRepositoryProtocol)? = nil,
        exerciseLibraryResolver: ExerciseLibraryResolver? = nil,
        store: ReceivedPlansStore? = nil
    ) {
        self.token = token
        self.shareAPIService = shareAPIService ?? DependencyContainer.shared.shareAPIService
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
        self.exerciseLibraryResolver = exerciseLibraryResolver ?? DependencyContainer.shared.exerciseLibraryResolver
        self.store = store ?? ReceivedPlansStore.shared
        self.isSaved = self.store.plan(token: token)?.isRead == true
    }

    // MARK: - Derived

    var isProgram: Bool { item?.type == .program }

    /// "▮ SENT BY MARCUS"
    var senderEyebrow: String {
        let name = plan?.sharedByName.trimmingCharacters(in: .whitespaces) ?? ""
        return VoidGlyphs.upNext(name.isEmpty ? "SENT TO YOU" : "SENT BY \(name)")
    }

    var title: String { plan?.name ?? "" }

    /// "4 DAYS · ~60 MIN · 8 WEEKS" plus a one-word descriptor when the description is short.
    var readout: String {
        guard let plan else { return "" }
        return VoidFormat.readout([plan.readout, descriptor])
    }

    /// A short description ("Strength") reads as a descriptor; sentences are omitted.
    private var descriptor: String? {
        let raw = (isProgram ? item?.program?.description : item?.template?.description)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty, raw.count <= 12, !raw.contains(" ") else { return nil }
        return raw.uppercased()
    }

    var ctaTitle: String { isProgram ? "Use this plan" : "Save workout" }

    /// Training days placed on consecutive days from Monday; the remaining days are rest.
    /// A single-workout share is just one tile.
    var dayCells: [DayCell] {
        guard let item else { return [] }
        switch item.type {
        case .template:
            let template = item.template
            return [DayCell(id: 0, label: VoidFormat.weekStripLabels[0], glyph: VoidIcon.workoutGlyph(for: template?.name), template: template)]
        case .program:
            let workouts = (item.program?.workouts ?? []).sorted { $0.dayNumber < $1.dayNumber }
            return VoidFormat.weekStripLabels.enumerated().map { index, label in
                if index < workouts.count {
                    let workout = workouts[index]
                    let name = workout.template?.name ?? workout.dayLabel
                    return DayCell(id: index, label: label, glyph: VoidIcon.workoutGlyph(for: name), template: workout.template)
                }
                return DayCell(id: index, label: label, glyph: nil, template: nil)
            }
        }
    }

    // MARK: - Loading

    func load() {
        state = .loading
        Task {
            await taskManager.run(id: "fetch-\(token)") { [weak self] in
                guard let self else { return }
                await self.performLoad()
            }
        }
    }

    func retry() { load() }

    private func performLoad() async {
        do {
            let response = try await shareAPIService.fetchShare(token: token)
            // Share payloads embed templates without the nested exercise object; hydrate
            // them so the preview shows real movement names.
            let fetched = await exerciseLibraryResolver.resolve(SharedItem.fromDTO(response))
            item = fetched
            plan = ReceivedPlan(item: fetched)
            // Every opened share is filed under Sent to you, unread, so a swiped-away sheet
            // is not lost; Save for later, Use this plan, or opening it from the list marks it read.
            if !store.contains(token: token) {
                store.save(ReceivedPlan(item: fetched, isRead: false))
            }
            isSaved = store.plan(token: token)?.isRead == true
            state = .loaded
        } catch let error as RepositoryError {
            if case .notFound = error {
                state = .error("This link is invalid or has expired.")
            } else {
                state = .error(error.errorDescription ?? "Could not load this plan.")
            }
        } catch {
            state = .error("Could not load this plan.")
        }
    }

    // MARK: - Actions

    /// Files the share under Sent to you (read) without importing anything.
    func saveForLater() {
        guard let item else { return }
        if !store.contains(token: token) {
            store.save(ReceivedPlan(item: item, isRead: false))
        }
        store.markRead(token: token)
        isSaved = true
    }

    /// Copies the share into the user's library. Programs are activated.
    /// A retry after a failed activation reuses what was already created instead of importing again.
    /// - Returns: true when the import finished.
    func use() async -> Bool {
        guard let item, state == .loaded || isErrorState else { return false }
        state = .importing
        do {
            switch item.type {
            case .program:
                let created: Program
                if let existing = importedProgram {
                    created = existing
                } else {
                    guard case .program(let program) = try await importer().performImport(item) else {
                        throw ImportError.missingProgram
                    }
                    created = program
                    importedProgram = program
                }
                do {
                    _ = try await programRepository.setActiveProgram(serverId: created.serverId)
                } catch {
                    state = .error("Plan saved, but it could not be activated. Try again to activate it.")
                    return false
                }

            case .template:
                if importedTemplate == nil {
                    guard case .template(let template) = try await importer().performImport(item) else {
                        throw ImportError.missingTemplate
                    }
                    importedTemplate = template
                }
            }

            store.markRead(token: token)
            isSaved = true
            state = .imported
            return true
        } catch let error as ImportError {
            state = .error(error.errorDescription ?? "Could not import this plan.")
        } catch let error as RepositoryError {
            state = .error(error.errorDescription ?? "Could not import this plan.")
        } catch {
            state = .error("Could not import this plan.")
        }
        return false
    }

    private func importer() -> ImportViewModel {
        ImportViewModel(
            shareAPIService: shareAPIService,
            templateRepository: templateRepository,
            programRepository: programRepository,
            exerciseLibraryResolver: exerciseLibraryResolver
        )
    }

    private var isErrorState: Bool {
        if case .error = state { return item != nil }
        return false
    }
}

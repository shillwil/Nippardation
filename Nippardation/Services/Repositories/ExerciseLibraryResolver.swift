//
//  ExerciseLibraryResolver.swift
//  Nippardation
//
//  Fills in the exercise library item that template exercises arrive without.
//

import Foundation

/// Hydrates `TemplateExercise.exerciseLibraryItem` so real movement names (and videos,
/// muscles, thumbnails) are available wherever a template came from.
///
/// The server only nests the full `exercise` object on the single-template endpoint.
/// List endpoints, program-embedded templates, share payloads and AI generation responses
/// all omit it, which is why an un-activated plan used to read "Exercise" on every row.
///
/// One resolver, used by both repositories and the view models that build templates
/// locally, does the same three steps every time:
///   1. the local exercise cache (`CDExerciseLibrary`),
///   2. the exercise API for whatever is still missing — deduplicated by
///      `exerciseServerId`, so a movement that appears on five days costs one request,
///   3. write what was fetched back into the cache for the next read.
///
/// Nothing here throws. A failed lookup leaves the exercise exactly as it was, so callers
/// keep whatever name they already had and an offline read still succeeds.
@MainActor
final class ExerciseLibraryResolver {

    // MARK: - Dependencies

    private let coreDataManager: CoreDataManager
    private let exerciseAPIService: (any ExerciseAPIServiceProtocol)?

    // MARK: - Configuration

    /// Ids whose network lookup failed, with the time it failed. Retried only after
    /// `failureBackoff`, so a dead network doesn't cost one request per exercise per screen.
    private var failedLookups: [String: Date] = [:]
    private let failureBackoff: TimeInterval = 60

    /// Upper bound on the requests a single resolve issues, so a huge plan can't storm the API.
    private let maxLookupsPerResolve = 60

    /// How many exercise lookups run at once.
    private let maxConcurrentLookups: Int

    // MARK: - Initialization

    init(
        coreDataManager: CoreDataManager = .shared,
        exerciseAPIService: (any ExerciseAPIServiceProtocol)? = nil,
        maxConcurrentLookups: Int = 4
    ) {
        self.coreDataManager = coreDataManager
        self.exerciseAPIService = exerciseAPIService
        self.maxConcurrentLookups = max(1, maxConcurrentLookups)
    }

    // MARK: - Cache only (synchronous)

    /// Resolves from the local cache only. Safe on any read path — no network, no throwing.
    func resolveFromCache(_ exercises: [TemplateExercise]) -> [TemplateExercise] {
        exercises.map { fromCache($0) }
    }

    func resolveFromCache(_ template: Template) -> Template {
        mapExercises(template) { fromCache($0) }
    }

    func resolveFromCache(_ program: Program) -> Program {
        mapExercises(program) { fromCache($0) }
    }

    // MARK: - Cache, then API

    func resolve(_ exercises: [TemplateExercise]) async -> [TemplateExercise] {
        var resolved: [TemplateExercise] = resolveFromCache(exercises)
        let items = await hydrate(ids: missingIds(resolved))
        if !items.isEmpty {
            resolved = resolved.map { applying(items, to: $0) }
        }
        await persistPlaceholders(resolved)
        return resolved
    }

    func resolve(_ template: Template) async -> Template {
        var resolved: Template = resolveFromCache(template)
        let items = await hydrate(ids: missingIds(resolved.exercises))
        if !items.isEmpty {
            resolved = mapExercises(resolved) { applying(items, to: $0) }
        }
        await persistPlaceholders(resolved.exercises)
        return resolved
    }

    func resolve(_ templates: [Template]) async -> [Template] {
        var resolved: [Template] = templates.map { resolveFromCache($0) }
        let items = await hydrate(ids: missingIds(resolved.flatMap { $0.exercises }))
        if !items.isEmpty {
            resolved = resolved.map { template -> Template in
                mapExercises(template) { applying(items, to: $0) }
            }
        }
        await persistPlaceholders(resolved.flatMap { $0.exercises })
        return resolved
    }

    func resolve(_ program: Program) async -> Program {
        var resolved: Program = resolveFromCache(program)
        let items = await hydrate(ids: missingIds(embeddedExercises(of: resolved)))
        if !items.isEmpty {
            resolved = mapExercises(resolved) { applying(items, to: $0) }
        }
        await persistPlaceholders(embeddedExercises(of: resolved))
        return resolved
    }

    func resolve(_ programs: [Program]) async -> [Program] {
        var resolved: [Program] = programs.map { resolveFromCache($0) }
        let items = await hydrate(ids: missingIds(resolved.flatMap { embeddedExercises(of: $0) }))
        if !items.isEmpty {
            resolved = resolved.map { program -> Program in
                mapExercises(program) { applying(items, to: $0) }
            }
        }
        await persistPlaceholders(resolved.flatMap { embeddedExercises(of: $0) })
        return resolved
    }

    /// A share payload: the same hydration for whichever of the two sides it carries.
    func resolve(_ item: SharedItem) async -> SharedItem {
        var template = item.template
        if let existing = template {
            template = await resolve(existing)
        }
        var program = item.program
        if let existing = program {
            program = await resolve(existing)
        }
        return SharedItem(
            token: item.token,
            type: item.type,
            sharedBy: item.sharedBy,
            sharedAt: item.sharedAt,
            template: template,
            program: program
        )
    }

    // MARK: - Single exercise

    /// True when this exercise has no library item, or only a name-only placeholder.
    func needsResolution(_ exercise: TemplateExercise) -> Bool {
        guard let item = exercise.exerciseLibraryItem else { return true }
        return item.isPlaceholder
    }

    /// Resolves one exercise from the local cache.
    private func fromCache(_ exercise: TemplateExercise) -> TemplateExercise {
        guard needsResolution(exercise), !exercise.exerciseServerId.isEmpty else { return exercise }
        guard let cached = coreDataManager.fetchCachedExercise(serverId: exercise.exerciseServerId) else {
            return exercise
        }
        let item = coreDataManager.toDomain(cached)
        // A cached placeholder only helps when we have nothing at all.
        if item.isPlaceholder && exercise.exerciseLibraryItem != nil { return exercise }
        var resolved = exercise
        resolved.exerciseLibraryItem = item
        return resolved
    }

    private func applying(_ items: [String: ExerciseLibraryItem], to exercise: TemplateExercise) -> TemplateExercise {
        guard needsResolution(exercise), let item = items[exercise.exerciseServerId] else { return exercise }
        var resolved = exercise
        resolved.exerciseLibraryItem = item
        return resolved
    }

    // MARK: - Lookups

    /// The exercise server ids that still need a library item, deduplicated and in order.
    private func missingIds(_ exercises: [TemplateExercise]) -> [String] {
        var seen = Set<String>()
        var ids: [String] = []
        for exercise in exercises where needsResolution(exercise) {
            let id = exercise.exerciseServerId
            guard !id.isEmpty, !seen.contains(id) else { continue }
            seen.insert(id)
            ids.append(id)
        }
        return ids
    }

    /// Fetches the given ids from the exercise API and caches what came back.
    /// Returns an empty table when there is no API, nothing to look up, or every call failed.
    private func hydrate(ids: [String]) async -> [String: ExerciseLibraryItem] {
        guard let api = exerciseAPIService else { return [:] }

        let now = Date()
        let eligible = ids.filter { id in
            guard let failedAt = failedLookups[id] else { return true }
            return now.timeIntervalSince(failedAt) >= failureBackoff
        }
        guard !eligible.isEmpty else { return [:] }
        let lookups = Array(eligible.prefix(maxLookupsPerResolve))

        var fetched: [String: ExerciseLibraryItem] = [:]
        var failed: [String] = []

        var index = 0
        while index < lookups.count {
            let end = min(index + maxConcurrentLookups, lookups.count)
            let batch = Array(lookups[index..<end])
            index = end

            let results = await withTaskGroup(
                of: (String, ExerciseLibraryItem?).self
            ) { group -> [(String, ExerciseLibraryItem?)] in
                for id in batch {
                    group.addTask {
                        guard let dto = try? await api.fetchExercise(id: id) else {
                            return (id, nil)
                        }
                        return (id, ExerciseMapper.toDomain(dto))
                    }
                }
                var collected: [(String, ExerciseLibraryItem?)] = []
                for await result in group {
                    collected.append(result)
                }
                return collected
            }

            for (id, item) in results {
                if let item {
                    fetched[id] = item
                } else {
                    failed.append(id)
                }
            }
        }

        let stamp = Date()
        for id in failed {
            failedLookups[id] = stamp
        }
        for id in fetched.keys {
            failedLookups.removeValue(forKey: id)
        }

        if !fetched.isEmpty {
            try? await coreDataManager.cacheExercises(Array(fetched.values))
        }
        return fetched
    }

    /// Keeps a name-only placeholder (an AI generation response, say) across a Core Data
    /// round trip without ever overwriting a real library entry.
    private func persistPlaceholders(_ exercises: [TemplateExercise]) async {
        var unique: [String: ExerciseLibraryItem] = [:]
        for exercise in exercises {
            guard let item = exercise.exerciseLibraryItem, item.isPlaceholder else { continue }
            guard !item.serverId.isEmpty else { continue }
            guard !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            if unique[item.serverId] == nil {
                unique[item.serverId] = item
            }
        }
        guard !unique.isEmpty else { return }
        try? await coreDataManager.cacheExercisesIfAbsent(Array(unique.values))
    }

    // MARK: - Container plumbing

    private func embeddedExercises(of program: Program) -> [TemplateExercise] {
        program.workouts.compactMap { $0.template }.flatMap { $0.exercises }
    }

    private func mapExercises(
        _ template: Template,
        _ transform: (TemplateExercise) -> TemplateExercise
    ) -> Template {
        var updated = template
        updated.exercises = template.exercises.map(transform)
        return updated
    }

    private func mapExercises(
        _ program: Program,
        _ transform: (TemplateExercise) -> TemplateExercise
    ) -> Program {
        var updated = program
        updated.workouts = program.workouts.map { workout in
            guard let template = workout.template else { return workout }
            var updatedWorkout = workout
            updatedWorkout.template = mapExercises(template, transform)
            return updatedWorkout
        }
        return updated
    }
}

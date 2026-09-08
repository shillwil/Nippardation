//
//  StarterPlanBuilder.swift
//  Nippardation
//
//  The five built-in starter splits, derived from the bundled workout lists
//  (pushDay / pullDay / legDay / upperStrength / lowerStrength), and the builder
//  that turns one into real workouts + a plan on the backend.
//

import Foundation

// MARK: - Splits

/// A workout inside a starter split, before it is matched to the exercise library.
struct StarterWorkout: Identifiable, Hashable {
    let id: String
    let name: String
    let exercises: [Exercise]

    static func == (lhs: StarterWorkout, rhs: StarterWorkout) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A built-in split: a few workouts and the order they rotate in.
struct StarterSplit: Identifiable, Hashable {
    let id: String
    let name: String
    let workouts: [StarterWorkout]
    /// Indexes into `workouts`, one per training day.
    let rotation: [Int]
    /// Day labels for the rotation (same count as `rotation`).
    let dayLabels: [String]

    var dayCount: Int { rotation.count }

    /// Average session length across the rotation.
    var estimatedMinutes: Int {
        let minutes = rotation.map { StarterPlanBuilder.estimatedMinutes(for: workouts[$0].exercises) }
        guard !minutes.isEmpty else { return 0 }
        return minutes.reduce(0, +) / minutes.count
    }

    /// "3 days · ~55 min"
    var caption: String {
        let days = "\(dayCount) \(dayCount == 1 ? "day" : "days")"
        return "\(days) · ~\(estimatedMinutes) min"
    }

    static func == (lhs: StarterSplit, rhs: StarterSplit) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Builder

@MainActor
final class StarterPlanBuilder: ObservableObject {

    enum BuildError: LocalizedError {
        case noExercises(workout: String)
        case cancelled

        var errorDescription: String? {
            switch self {
            case .noExercises(let workout):
                return "None of the exercises in \(workout) were found in the library, so the plan was not created."
            case .cancelled:
                return "Building was cancelled."
            }
        }
    }

    @Published private(set) var isBuilding = false
    /// "Building…" / "Matching exercises 04 / 21"
    @Published private(set) var progressText = "Building…"
    @Published var error: String?
    /// The created + activated plan.
    @Published private(set) var builtProgram: Program?

    private let exerciseRepository: any ExerciseRepositoryProtocol
    private let templateRepository: any TemplateRepositoryProtocol
    private let programRepository: any ProgramRepositoryProtocol

    /// Query → best match, so repeated exercises hit the network once.
    private var matchCache: [String: ExerciseLibraryItem?] = [:]

    init(
        exerciseRepository: (any ExerciseRepositoryProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil,
        programRepository: (any ProgramRepositoryProtocol)? = nil
    ) {
        self.exerciseRepository = exerciseRepository ?? DependencyContainer.shared.exerciseRepository
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
    }

    // MARK: - The five splits

    static let push = StarterWorkout(id: "push", name: "Push", exercises: pushDay.exercises)
    static let pull = StarterWorkout(id: "pull", name: "Pull", exercises: pullDay.exercises)
    static let legs = StarterWorkout(id: "legs", name: "Legs", exercises: legDay.exercises)
    static let upper = StarterWorkout(id: "upper", name: "Upper", exercises: upperStrength.exercises)
    static let lower = StarterWorkout(id: "lower", name: "Lower", exercises: lowerStrength.exercises)

    /// Six compound moves picked across the lists.
    static let fullBody = StarterWorkout(
        id: "full-body",
        name: "Full Body",
        exercises: pick([
            ("Barbell Bench Press", pushDay),
            ("Chest-Supported Machine Row", pullDay),
            ("Leg Press", legDay),
            ("Machine Shoulder Press", pushDay),
            ("Barbell RDL", lowerStrength),
            ("Wide Grip Pull-Up", upperStrength)
        ])
    )

    static let splits: [StarterSplit] = [
        StarterSplit(
            id: "ppl",
            name: "Push / Pull / Legs",
            workouts: [push, pull, legs],
            rotation: [0, 1, 2],
            dayLabels: ["Push", "Pull", "Legs"]
        ),
        StarterSplit(
            id: "ul",
            name: "Upper / Lower",
            workouts: [upper, lower],
            rotation: [0, 1],
            dayLabels: ["Upper", "Lower"]
        ),
        StarterSplit(
            id: "full",
            name: "Full body",
            workouts: [fullBody],
            rotation: [0],
            dayLabels: ["Full Body"]
        ),
        StarterSplit(
            id: "ppl2",
            name: "PPL × 2",
            workouts: [push, pull, legs],
            rotation: [0, 1, 2, 0, 1, 2],
            dayLabels: ["Push A", "Pull A", "Legs A", "Push B", "Pull B", "Legs B"]
        ),
        StarterSplit(
            id: "ul2",
            name: "Upper / Lower × 2",
            workouts: [upper, lower],
            rotation: [0, 1, 0, 1],
            dayLabels: ["Upper A", "Lower A", "Upper B", "Lower B"]
        )
    ]

    private static func pick(_ wanted: [(String, Workout)]) -> [Exercise] {
        wanted.compactMap { name, workout in
            workout.exercises.first { $0.type.name.caseInsensitiveCompare(name) == .orderedSame }
        }
    }

    // MARK: - Estimates

    /// Same shape as `Template.estimatedDurationMinutes`: sets × (45s + rest), rounded to 5.
    nonisolated static func estimatedMinutes(for exercises: [Exercise]) -> Int {
        guard !exercises.isEmpty else { return 0 }
        let sets = exercises.reduce(0) { $0 + $1.warmUpSets + $1.workingSets }
        let rests = exercises.map { restSeconds(for: $0) }
        let averageRest = rests.reduce(0, +) / max(rests.count, 1)
        let minutes = sets * (45 + averageRest) / 60
        return max(5, Int((Double(minutes) / 5).rounded()) * 5)
    }

    /// The data files hold rest in minutes; use the midpoint in seconds.
    nonisolated static func restSeconds(for exercise: Exercise) -> Int {
        let lower = exercise.rest.lowerBound
        let upper = exercise.rest.upperBound
        return (lower + upper) * 30
    }

    nonisolated static func targetReps(for exercise: Exercise) -> String {
        let lower = exercise.reps.lowerBound
        let upper = exercise.reps.upperBound
        return lower == upper ? "\(lower)" : "\(lower)-\(upper)"
    }

    // MARK: - Build

    /// Creates the split's workouts and plan, then activates the plan.
    /// - Returns: true on success; on failure `error` is set.
    @discardableResult
    func build(_ split: StarterSplit) async -> Bool {
        guard !isBuilding else { return false }
        isBuilding = true
        error = nil
        builtProgram = nil
        progressText = "Building…"
        defer { isBuilding = false }

        do {
            let total = split.workouts.reduce(0) { $0 + $1.exercises.count }
            var matched = 0

            // 1. Match every exercise name against the library and create the workouts.
            var templates: [Template] = []
            for workout in split.workouts {
                var templateExercises: [TemplateExercise] = []
                for exercise in workout.exercises {
                    matched += 1
                    progressText = "Matching exercises \(VoidFormat.ratio(matched, total))"
                    try Task.checkCancellation()
                    guard let item = await bestMatch(for: exercise.type.name) else { continue }
                    templateExercises.append(
                        TemplateExercise.from(
                            libraryItem: item,
                            orderIndex: templateExercises.count,
                            workingSets: exercise.workingSets,
                            warmupSets: exercise.warmUpSets > 0 ? exercise.warmUpSets : nil,
                            targetReps: Self.targetReps(for: exercise),
                            restSeconds: Self.restSeconds(for: exercise)
                        )
                    )
                }
                guard !templateExercises.isEmpty else {
                    throw BuildError.noExercises(workout: workout.name)
                }
                progressText = "Saving \(workout.name)…"
                var template = Template.empty(name: workout.name)
                template.exercises = templateExercises
                let created = try await templateRepository.createTemplate(template)
                templates.append(created)
            }

            // 2. Create the plan from the rotation.
            progressText = "Saving plan…"
            let workouts = split.rotation.enumerated().map { day, index in
                ProgramWorkout.from(
                    template: templates[index],
                    dayNumber: day,
                    dayLabel: day < split.dayLabels.count ? split.dayLabels[day] : nil
                )
            }
            var program = Program.empty(name: split.name)
            program.workouts = workouts
            program.daysPerWeek = split.dayCount
            program.durationWeeks = nil
            let created = try await programRepository.createProgram(program)

            // 3. Make it the active plan.
            progressText = "Activating…"
            let active = try await programRepository.setActiveProgram(serverId: created.serverId)
            builtProgram = active
            return true
        } catch is CancellationError {
            self.error = BuildError.cancelled.errorDescription
        } catch let buildError as BuildError {
            self.error = buildError.errorDescription
        } catch let repositoryError as RepositoryError {
            self.error = repositoryError.errorDescription ?? "Could not build this plan."
        } catch {
            self.error = "Could not build this plan."
        }
        return false
    }

    // MARK: - Matching

    /// Best library match for an exercise name: full-name search first, then the
    /// name with equipment/grip qualifiers stripped, then the last two words.
    func bestMatch(for name: String) async -> ExerciseLibraryItem? {
        if let cached = matchCache[name] { return cached }

        var queries: [String] = [name]
        let stripped = Self.strippedName(name)
        if stripped != name, !stripped.isEmpty { queries.append(stripped) }
        let tail = Self.tail(of: stripped.isEmpty ? name : stripped, words: 2)
        if !queries.contains(tail), !tail.isEmpty { queries.append(tail) }

        var best: (item: ExerciseLibraryItem, score: Double)?
        for query in queries {
            let results = (try? await exerciseRepository.searchExercises(query: query, limit: 10)) ?? []
            for item in results {
                let score = Self.score(candidate: item.name, wanted: name)
                if score > 0, score > (best?.score ?? 0) {
                    best = (item, score)
                }
            }
            if let best, best.score >= 0.99 { break }
        }

        matchCache[name] = best?.item
        return best?.item
    }

    /// Lowercased alphanumeric tokens, singularised.
    nonisolated static func tokens(_ text: String) -> [String] {
        text.lowercased()
            .replacingOccurrences(of: "°", with: " ")
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { word -> String in
                var w = String(word)
                if w.count > 3, w.hasSuffix("s") { w.removeLast() }
                return w
            }
            .filter { !$0.isEmpty }
    }

    nonisolated static func strippedName(_ name: String) -> String {
        tokens(name).filter { !starterQualifiers.contains($0) }.joined(separator: " ")
    }

    nonisolated static func tail(of name: String, words: Int) -> String {
        tokens(name).suffix(words).joined(separator: " ")
    }

    /// 1 for an exact (normalised) match; otherwise the share of the wanted words the
    /// candidate contains, lightly penalised for extra words. 0 when nothing overlaps.
    nonisolated static func score(candidate: String, wanted: String) -> Double {
        let c = tokens(candidate)
        let w = tokens(wanted)
        guard !c.isEmpty, !w.isEmpty else { return 0 }
        if c == w { return 1 }
        if candidate.localizedCaseInsensitiveCompare(wanted) == .orderedSame { return 1 }
        let cSet = Set(c), wSet = Set(w)
        let shared = cSet.intersection(wSet).count
        guard shared > 0 else { return 0 }
        let coverage = Double(shared) / Double(wSet.count)
        let extra = Double(cSet.count - shared) / Double(max(cSet.count, 1))
        return max(0.01, coverage - extra * 0.25)
    }
}

/// Qualifiers that rarely appear in library names; dropped for the fallback searches.
private let starterQualifiers: Set<String> = [
    "machine", "cable", "db", "dumbbell", "barbell", "ez", "bar", "smith", "neutral", "grip",
    "wide", "close", "seated", "standing", "lying", "chest", "supported", "high", "low",
    "bottom", "half", "arm", "1", "45", "deficit", "roman", "chair"
]

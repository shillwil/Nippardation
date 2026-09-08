//
//  AIWizardViewModel.swift
//  Nippardation
//
//  ViewModel for the AI program generation wizard
//

import Foundation
import Combine

@MainActor
final class AIWizardViewModel: ObservableObject {

    // MARK: - Step 1: Goal & Split

    @Published var selectedGoal: AITrainingGoal = .hypertrophy
    @Published var inspirationSource: String = ""
    @Published var selectedSplitSuggestion: AISplitSuggestion?

    // MARK: - Step 2: Schedule

    @Published var daysPerWeek: Int = 4
    @Published var sessionDurationMinutes: Int = 60

    // MARK: - Step 3: Equipment & Experience

    @Published var selectedEquipment: Set<AIEquipment> = Set(AIEquipment.allCases)
    @Published var experienceLevel: AIExperienceLevel = .intermediate

    // MARK: - Step 4: Preferences

    @Published var freeTextPreferences: String = ""
    @Published var useTrainingHistory: Bool = false
    @Published var strengthEntries: [StrengthDataEntry] = []

    // MARK: - Template Reuse

    @Published var reuseTemplates: Bool = false
    @Published var selectedTemplateIds: Set<String> = []
    @Published var availableTemplates: [Template] = []
    @Published var isLoadingTemplates = false
    @Published var reusedTemplateIds: Set<String> = []

    // MARK: - Generation State

    @Published var isGenerating = false
    @Published var isLoadingQuota = false
    @Published var isLoadingProfile = false
    @Published var generationStatus: AIGenerationStatus?
    @Published var generatedProgram: Program?
    @Published var generationMetadata: GenerationMetadataDTO?
    @Published var error: String?
    @Published var errorIsRetryable = false
    @Published var generationComplete = false

    // MARK: - Loading Messages

    @Published var loadingMessageIndex = 0
    let loadingMessages = [
        "Analyzing your goals...",
        "Selecting exercises...",
        "Building your plan...",
        "Optimizing your split...",
        "Fine-tuning volume...",
        "Almost there..."
    ]

    // MARK: - Dependencies

    private let aiAPIService: any AIAPIServiceProtocol
    private let programRepository: any ProgramRepositoryProtocol
    private let templateRepository: any TemplateRepositoryProtocol
    private var generateTask: Task<Void, Never>?
    private var loadingTimer: Timer?

    // MARK: - Validation

    var isStep1Valid: Bool {
        // Must have a goal selected (always true since it has a default)
        // inspirationSource (split preference) is optional but encouraged
        true
    }

    var isStep2Valid: Bool {
        daysPerWeek >= 1 && daysPerWeek <= 7 &&
        sessionDurationMinutes >= 30 && sessionDurationMinutes <= 120
    }

    var isStep3Valid: Bool {
        guard AppConfiguration.shared.sendEquipmentToAI else { return true }
        return !selectedEquipment.isEmpty
    }

    var isStep4Valid: Bool {
        generationStatus?.hasRemaining ?? true
    }

    var canGenerate: Bool {
        isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid && !isGenerating
    }

    // MARK: - Initialization

    init(
        aiAPIService: (any AIAPIServiceProtocol)? = nil,
        programRepository: (any ProgramRepositoryProtocol)? = nil,
        templateRepository: (any TemplateRepositoryProtocol)? = nil
    ) {
        self.aiAPIService = aiAPIService ?? DependencyContainer.shared.aiAPIService
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
    }

    // MARK: - Public Methods

    func loadQuota() {
        Task {
            isLoadingQuota = true
            do {
                let status = try await aiAPIService.fetchGenerationStatus()
                generationStatus = AIGenerationStatus.from(status)
            } catch {
                // Non-critical: allow user to proceed even if quota check fails
                #if DEBUG
                print("Failed to fetch generation status: \(error)")
                #endif
            }
            isLoadingQuota = false
        }
    }

    func loadStrengthProfile() {
        Task {
            isLoadingProfile = true
            do {
                let profile = try await aiAPIService.fetchStrengthProfile()
                strengthEntries = profile.entries.map { entry in
                    StrengthDataEntry(
                        exerciseName: entry.exerciseName,
                        weight: entry.weight,
                        unit: entry.unit,
                        reps: entry.reps,
                        sets: entry.sets
                    )
                }
            } catch {
                // Non-critical: user can enter data manually
                #if DEBUG
                print("Failed to fetch strength profile: \(error)")
                #endif
            }
            isLoadingProfile = false
        }
    }

    func selectSplitSuggestion(_ suggestion: AISplitSuggestion) {
        if selectedSplitSuggestion == suggestion {
            selectedSplitSuggestion = nil
            inspirationSource = ""
        } else {
            selectedSplitSuggestion = suggestion
            inspirationSource = suggestion.rawValue
        }
    }

    func addStrengthEntry() {
        guard strengthEntries.count < 20 else { return }
        strengthEntries.append(StrengthDataEntry(
            exerciseName: "",
            weight: 0,
            unit: "lb",
            reps: 0,
            sets: 0
        ))
    }

    func removeStrengthEntry(at offsets: IndexSet) {
        strengthEntries.remove(atOffsets: offsets)
    }

    // MARK: - Template Reuse

    func loadTemplates() {
        guard !isLoadingTemplates else { return }
        isLoadingTemplates = true

        Task {
            do {
                let templates = try await templateRepository.fetchTemplates(forceRefresh: false)
                await MainActor.run {
                    self.availableTemplates = templates
                    self.isLoadingTemplates = false
                }
            } catch {
                await MainActor.run {
                    self.availableTemplates = []
                    self.isLoadingTemplates = false
                }
            }
        }
    }

    func toggleTemplateSelection(_ templateId: String) {
        if selectedTemplateIds.contains(templateId) {
            selectedTemplateIds.remove(templateId)
        } else {
            guard selectedTemplateIds.count < 7 else { return }
            selectedTemplateIds.insert(templateId)
        }
    }

    func generate() {
        guard canGenerate else { return }

        isGenerating = true
        error = nil
        loadingMessageIndex = 0
        startLoadingMessages()

        generateTask = Task { [weak self] in
            guard let self = self else { return }

            // Build the inspirationSource: combine split suggestion with any custom text
            let source = self.inspirationSource.trimmingCharacters(in: .whitespaces)
            let finalInspirationSource = source.isEmpty ? self.selectedGoal.displayName : source

            // Filter out empty strength entries
            let validStrengthData = self.strengthEntries.filter { !$0.exerciseName.isEmpty && $0.weight > 0 }

            let reuseIds = self.reuseTemplates && !self.selectedTemplateIds.isEmpty
                ? Array(self.selectedTemplateIds) : nil

            let request = GenerateProgramRequest(
                inspirationSource: finalInspirationSource,
                daysPerWeek: self.daysPerWeek,
                sessionDurationMinutes: self.sessionDurationMinutes,
                experienceLevel: self.experienceLevel.rawValue,
                goal: self.selectedGoal.rawValue,
                equipment: self.selectedEquipment.map(\.rawValue),
                useTrainingHistory: self.useTrainingHistory,
                manualStrengthData: validStrengthData.isEmpty ? nil : validStrengthData,
                freeTextPreferences: self.freeTextPreferences.isEmpty ? nil : self.freeTextPreferences,
                reuseTemplateIds: reuseIds
            )

            do {
                let response = try await self.aiAPIService.generateProgram(request)

                // Map the AI-specific DTO to a domain model
                let program = AIGeneratedProgramMapper.toDomain(response.program)

                // Extract reused template IDs from the response
                let reusedIds = Set(
                    (response.program.workouts ?? [])
                        .compactMap { $0.template }
                        .filter { $0.wasReused == true }
                        .compactMap { $0.id }
                )

                // Cache the generated program and its templates locally
                try? await self.programRepository.cacheProgram(program)
                for workout in program.workouts {
                    if let template = workout.template {
                        try? await self.templateRepository.cacheTemplate(template)
                    }
                }

                await MainActor.run {
                    self.generatedProgram = program
                    self.generationMetadata = response.generation
                    self.reusedTemplateIds = reusedIds
                    self.isGenerating = false
                    self.generationComplete = true
                    self.stopLoadingMessages()

                    // Update quota after successful generation
                    if var status = self.generationStatus {
                        self.generationStatus = AIGenerationStatus(
                            generationsUsed: status.generationsUsed + 1,
                            generationsRemaining: max(0, status.generationsRemaining - 1),
                            generationsLimit: status.generationsLimit,
                            resetsAt: status.resetsAt,
                            tier: status.tier
                        )
                    }
                }

                // Save strength data if provided
                if !validStrengthData.isEmpty {
                    try? await self.aiAPIService.saveStrengthProfile(
                        StrengthProfileRequest(entries: validStrengthData)
                    )
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.isGenerating = false
                    self.stopLoadingMessages()
                }
            } catch let repoError as RepositoryError {
                await MainActor.run {
                    self.isGenerating = false
                    self.stopLoadingMessages()
                    self.error = repoError.errorDescription
                    self.errorIsRetryable = repoError.isRetryable
                }
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                    self.stopLoadingMessages()
                    self.error = "Couldn't generate a plan. Try again."
                    self.errorIsRetryable = true
                }
            }
        }
    }

    func cancelGeneration() {
        generateTask?.cancel()
        generateTask = nil
        isGenerating = false
        stopLoadingMessages()
    }

    func clearError() {
        error = nil
        errorIsRetryable = false
    }

    func discardGeneratedProgram() {
        guard let program = generatedProgram else { return }

        Task {
            // Clean up the server-side program
            try? await programRepository.deleteProgram(serverId: program.serverId)
        }

        generatedProgram = nil
        generationMetadata = nil
        generationComplete = false
    }

    // MARK: - Private

    private func startLoadingMessages() {
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isGenerating else { return }
                self.loadingMessageIndex = (self.loadingMessageIndex + 1) % self.loadingMessages.count
            }
        }
    }

    private func stopLoadingMessages() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }
}

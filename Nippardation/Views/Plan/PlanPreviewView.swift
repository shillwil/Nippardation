//
//  PlanPreviewView.swift
//  Nippardation
//
//  Read-only rotation for a plan that is not (yet) the active one: the same rows as the
//  Plan tab, all in the "later" state, with an Activate CTA at the bottom when the plan
//  belongs to the user. Used from the Plans hub and from the Plan received sheet.
//

import SwiftUI

struct PlanPreviewView: View {
    let program: Program
    /// A plan someone shared: not the user's, so nothing is fetched and there is no Activate.
    var isShared: Bool = false

    @EnvironmentObject private var navigation: AppNavigation
    @Environment(\.dismiss) private var dismiss

    @State private var detail: Program?
    @State private var isActivating = false
    @State private var errorMessage: String?

    private var programRepository: any ProgramRepositoryProtocol { DependencyContainer.shared.programRepository }

    init(program: Program, isShared: Bool = false) {
        self.program = program
        self.isShared = isShared
    }

    private var displayProgram: Program { detail ?? program }

    /// The rotation with every row in the later state; weekdays projected from today.
    private var rows: [RotationRow] {
        PlanRotationBuilder.rows(for: displayProgram, now: Date()).map { row in
            RotationRow(
                id: row.id,
                index: row.index,
                workout: row.workout,
                template: row.template,
                state: .later,
                weekday: row.weekday,
                date: row.date
            )
        }
    }

    private var readout: String {
        let program = displayProgram
        let days = program.workouts.isEmpty ? program.daysPerWeek : program.workouts.count
        var parts: [String?] = [VoidFormat.days(days)]
        if let weeks = program.durationWeeks, weeks > 0 { parts.append(VoidFormat.weeks(weeks)) }
        let minutes = program.workouts.compactMap { $0.template?.estimatedDurationMinutes }.filter { $0 > 0 }
        if !minutes.isEmpty { parts.append(VoidFormat.minutes(minutes.reduce(0, +) / minutes.count)) }
        return VoidFormat.readout(parts)
    }

    private var showsActivate: Bool { !isShared && !displayProgram.isActive }

    var body: some View {
        Group {
            if rows.isEmpty {
                ContentUnavailableView(
                    "No workouts",
                    systemImage: VoidIcon.barbell.systemName,
                    description: Text("This plan has no workout days yet.")
                )
            } else {
                List {
                    Section {
                        ForEach(rows) { row in
                            rotationRow(row)
                                // Flush leading edge for the up-next mark; the chevron keeps the card inset.
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: VoidSpace.insetCard))
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(VoidColor.hairline)
                        }
                    } header: {
                        Text(readout)
                    }
                }
                .listStyle(.plain)
            }
        }
        .planBottomBar {
            if showsActivate {
                VoidCTAButton(title: "Activate", isLoading: isActivating) { activate() }
                    .padding(.horizontal, VoidSpace.insetCard)
                    .padding(.vertical, VoidSpace.s3)
            }
        }
        .navigationTitle(displayProgram.name)
        .navigationBarTitleDisplayMode(.inline)
        .voidScreen()
        .task { await loadDetail() }
        .alert("Could not activate", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Rows

    /// A day with exercises pushes its workout preview; one without has nothing to show.
    @ViewBuilder
    private func rotationRow(_ row: RotationRow) -> some View {
        if let template = row.template, !template.exercises.isEmpty {
            NavigationLink {
                WorkoutPreviewView(template: template)
            } label: {
                PlanRotationRow(row: row)
            }
        } else {
            PlanRotationRow(row: row)
        }
    }

    // MARK: - Data

    private func loadDetail() async {
        guard !isShared, !program.serverId.isEmpty else { return }
        if let fetched = try? await programRepository.fetchProgram(serverId: program.serverId, forceRefresh: false) {
            detail = fetched
        }
    }

    private func activate() {
        guard !isActivating else { return }
        isActivating = true
        Task {
            do {
                _ = try await programRepository.setActiveProgram(serverId: displayProgram.serverId)
                isActivating = false
                navigation.planDidChange()
                dismiss()
                navigation.show(.today)
            } catch let error as RepositoryError {
                isActivating = false
                errorMessage = error.errorDescription ?? "Could not activate this plan."
            } catch {
                isActivating = false
                errorMessage = "Could not activate this plan."
            }
        }
    }
}

// MARK: - Previews

#Preview("Inactive plan") {
    NavigationStack {
        PlanPreviewView(program: MockData.inactiveProgram)
    }
    .environmentObject(AppNavigation())
    .withDependencies(.preview)
}

#Preview("Shared plan") {
    NavigationStack {
        PlanPreviewView(program: MockData.activeProgram, isShared: true)
    }
    .environmentObject(AppNavigation())
    .withDependencies(.preview)
}

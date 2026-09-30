//
//  ProgramDeleteConfirmationView.swift
//  Nippardation
//
//  Delete an AI plan: choose which of its AI-generated workouts to keep.
//  The backend handles safety — only AI workouts no other plan uses are deleted.
//

import SwiftUI

struct ProgramDeleteConfirmationView: View {
    let program: Program
    var isDeletingProgram: Bool = false
    let onConfirmDelete: ([String]) -> Void
    let onCancel: () -> Void

    @State private var keepTemplateIds: Set<String> = []

    private typealias AITemplate = (serverId: String, name: String, exerciseCount: Int)

    /// Unique workouts from the plan's days (deduplicated by server ID).
    private var aiTemplates: [AITemplate] {
        var seen = Set<String>()
        var result: [AITemplate] = []

        for workout in program.workouts {
            guard let template = workout.template,
                  !seen.contains(workout.templateServerId) else { continue }
            seen.insert(workout.templateServerId)
            result.append((
                serverId: workout.templateServerId,
                name: template.name,
                exerciseCount: template.exerciseCount
            ))
        }

        return result.sorted { $0.name < $1.name }
    }

    private var deletingCount: Int { aiTemplates.count - keepTemplateIds.count }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                introSection
                if !aiTemplates.isEmpty {
                    workoutsSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Delete plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: onCancel)
                        .disabled(isDeletingProgram)
                }
            }
            // Pinned below the list, so the sheet's one action is in view at the medium detent.
            .deleteActionBar { deleteBar }
            .disabled(isDeletingProgram)
        }
        // No fill of our own, so the partial-height sheet keeps the system sheet background.
        .tint(VoidColor.plasmaInk)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isDeletingProgram)
    }

    // MARK: - Sections

    /// The plan being deleted, above the list of its workouts.
    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: VoidSpace.s2) {
                Text(program.name)
                    .font(VoidFont.title)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(2)
                Text("This plan came with \(aiTemplates.count) AI \(aiTemplates.count == 1 ? "workout" : "workouts"). Keep the ones you still want.")
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .listRowBackground(Color.clear)
        }
    }

    /// One switch per workout: on keeps it, off deletes it with the plan.
    private var workoutsSection: some View {
        Section {
            ForEach(aiTemplates, id: \.serverId) { template in
                Toggle(isOn: keepBinding(for: template.serverId)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(VoidFont.bodyStrong)
                            .foregroundStyle(VoidColor.text)
                            .lineLimit(1)
                        Text("\(template.exerciseCount) \(template.exerciseCount == 1 ? "exercise" : "exercises")")
                            .font(VoidFont.caption2)
                            .foregroundStyle(VoidColor.text2)
                            .lineLimit(1)
                    }
                }
                .tint(VoidColor.plasma)
                .accessibilityHint("On keeps this workout after the plan is deleted")
                .listRowBackground(VoidColor.panel)
                .listRowSeparatorTint(VoidColor.hairline)
            }
        } header: {
            HStack {
                Text("Keep workouts")
                Spacer()
                Group {
                    Button("Keep all") {
                        keepTemplateIds = Set(aiTemplates.map(\.serverId))
                    }
                    .disabled(keepTemplateIds.count == aiTemplates.count)
                    Button("Delete all") {
                        keepTemplateIds = []
                    }
                    .disabled(keepTemplateIds.isEmpty)
                }
                .buttonStyle(.borderless)
                // Header text may be uppercased by the list; the buttons keep their own case.
                .textCase(nil)
            }
        } footer: {
            Text(summary)
                .foregroundStyle(keepTemplateIds.isEmpty ? VoidColor.warning : VoidColor.text2)
        }
    }

    // MARK: - Delete action

    /// The destructive action for the bottom bar. While the deletion runs, a spinner takes the
    /// title's place and the button keeps its size, so the bar doesn't jump.
    private var deleteBar: some View {
        Button(role: .destructive) {
            onConfirmDelete(Array(keepTemplateIds))
        } label: {
            Text("Delete plan")
                .font(.headline)
                .opacity(isDeletingProgram ? 0 : 1)
                .overlay {
                    if isDeletingProgram {
                        // On the system's disabled fill, where secondary ink reads in both appearances.
                        ProgressView()
                            .controlSize(.regular)
                            .tint(VoidColor.text2)
                    }
                }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(.red) // the plasma tint would otherwise recolour it
        .disabled(isDeletingProgram)
        // The title is hidden, not removed, while deleting; say it outright so VoiceOver always has it.
        .accessibilityLabel(Text("Delete plan"))
        .accessibilityValue(isDeletingProgram ? Text("Deleting") : Text(""))
        .padding(.horizontal, VoidSpace.insetCard)
        .padding(.top, VoidSpace.s3)
        .padding(.bottom, VoidSpace.s2)
    }

    // MARK: - Derived

    /// "Keeping 2 workouts, deleting 1." or "Deleting the plan and all 3 workouts."
    private var summary: String {
        if keepTemplateIds.isEmpty {
            return aiTemplates.count == 1
                ? "Deleting the plan and its workout."
                : "Deleting the plan and all \(aiTemplates.count) workouts."
        }
        if deletingCount == 0 {
            return "Keeping every workout. Only the plan is deleted."
        }
        return "Keeping \(keepTemplateIds.count) \(keepTemplateIds.count == 1 ? "workout" : "workouts"), deleting \(deletingCount)."
    }

    private func keepBinding(for serverId: String) -> Binding<Bool> {
        Binding(
            get: { keepTemplateIds.contains(serverId) },
            set: { isKept in
                if isKept {
                    keepTemplateIds.insert(serverId)
                } else {
                    keepTemplateIds.remove(serverId)
                }
            }
        )
    }
}

// MARK: - Bottom bar

private extension View {
    /// Pins the delete action below the list. On iOS 26 it is a safe-area bar, so rows scroll under
    /// it with the system scroll-edge effect; earlier versions put it on the system bar material.
    @ViewBuilder
    func deleteActionBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .bottom) { bar() }
        } else {
            safeAreaInset(edge: .bottom, spacing: 0) {
                bar().background(.bar)
            }
        }
    }
}

// MARK: - Previews

#Preview("Delete AI plan") {
    VoidColor.hull.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ProgramDeleteConfirmationView(
                program: MockProgramRepository.samplePrograms[0],
                onConfirmDelete: { _ in },
                onCancel: {}
            )
        }
}

#Preview("Deleting") {
    VoidColor.hull.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ProgramDeleteConfirmationView(
                program: MockProgramRepository.samplePrograms[1],
                isDeletingProgram: true,
                onConfirmDelete: { _ in },
                onCancel: {}
            )
        }
}

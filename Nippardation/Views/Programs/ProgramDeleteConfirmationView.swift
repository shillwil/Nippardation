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
        VStack(spacing: 0) {
            VoidGrabber()
                .padding(.top, 10)
                .padding(.bottom, 22)

            VStack(alignment: .leading, spacing: VoidSpace.s2) {
                Text("Delete plan").voidEyebrow(VoidColor.warning)
                Text(program.name)
                    .font(VoidFont.title)
                    .foregroundStyle(VoidColor.text)
                    .lineLimit(2)
                Text("This plan came with \(aiTemplates.count) AI \(aiTemplates.count == 1 ? "workout" : "workouts"). Keep the ones you still want.")
                    .font(VoidFont.caption)
                    .foregroundStyle(VoidColor.text2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(aiTemplates.enumerated()), id: \.element.serverId) { index, template in
                        templateRow(template)
                        if index < aiTemplates.count - 1 {
                            VoidHairline()
                        }
                    }
                }
                .padding(.vertical, VoidSpace.s3)
            }
            .scrollBounceBehavior(.basedOnSize)

            HStack(spacing: 10) {
                VoidPillButton(title: "Keep all", isEnabled: keepTemplateIds.count < aiTemplates.count) {
                    keepTemplateIds = Set(aiTemplates.map(\.serverId))
                }
                VoidPillButton(title: "Delete all", isEnabled: !keepTemplateIds.isEmpty) {
                    keepTemplateIds = []
                }
            }
            .padding(.bottom, VoidSpace.s3)

            Text(summary)
                .voidEyebrowSm(keepTemplateIds.isEmpty ? VoidColor.warning : VoidColor.text2)
                .frame(maxWidth: .infinity)
                .padding(.bottom, VoidSpace.s3)

            if isDeletingProgram {
                ProgressView()
                    .tint(VoidColor.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: VoidSize.pill)
            } else {
                VoidDestructiveButton(title: "Delete plan") {
                    onConfirmDelete(Array(keepTemplateIds))
                }
            }

            VoidPillButton(title: "Cancel", isEnabled: !isDeletingProgram, action: onCancel)
                .padding(.top, 10)
        }
        .padding(.horizontal, VoidSpace.insetText)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(VoidColor.panel)
        .voidSheet()
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(isDeletingProgram)
    }

    /// "KEEPING 02 · DELETING 01" or "DELETING THE PLAN AND ALL 03 WORKOUTS"
    private var summary: String {
        if keepTemplateIds.isEmpty {
            return "Deleting the plan and all \(VoidFormat.pad2(aiTemplates.count)) \(aiTemplates.count == 1 ? "workout" : "workouts")"
        }
        return VoidFormat.readout([
            "Keeping \(VoidFormat.pad2(keepTemplateIds.count))",
            "deleting \(VoidFormat.pad2(deletingCount))"
        ])
    }

    // MARK: - Workout row

    private func templateRow(_ template: AITemplate) -> some View {
        let isKept = keepTemplateIds.contains(template.serverId)

        return Button {
            if isKept {
                keepTemplateIds.remove(template.serverId)
            } else {
                keepTemplateIds.insert(template.serverId)
            }
        } label: {
            HStack(spacing: VoidSpace.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: VoidRadius.avatar, style: .continuous)
                        .fill(VoidColor.panel2)
                    if isKept {
                        Image(systemName: VoidIcon.check.systemName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(VoidColor.plasma)
                    }
                }
                .frame(width: VoidSize.avatar, height: VoidSize.avatar)

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                    Text("\(template.exerciseCount) \(template.exerciseCount == 1 ? "exercise" : "exercises")")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                }

                Spacer(minLength: VoidSpace.s2)

                Text(isKept ? "Keep" : "Delete")
                    .voidEyebrowSm(isKept ? VoidColor.plasma : VoidColor.warning)
            }
            .frame(height: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidRowButtonStyle())
        .accessibilityLabel("\(template.name), \(isKept ? "kept" : "deleted")")
        .accessibilityHint(isKept ? "Marks the workout for deletion" : "Keeps the workout")
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

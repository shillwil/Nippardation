//
//  ProgramDeleteConfirmationView.swift
//  Nippardation
//
//  Confirmation sheet for deleting an AI program with selective template cleanup
//

import SwiftUI

struct ProgramDeleteConfirmationView: View {
    let program: Program
    var isDeletingProgram: Bool = false
    let onConfirmDelete: ([String]) -> Void
    let onCancel: () -> Void

    @State private var keepTemplateIds: Set<String> = []

    /// Unique templates from the program's workouts (deduplicated by server ID).
    /// The backend handles safety — only AI-generated templates not used elsewhere get deleted.
    private var aiTemplates: [(serverId: String, name: String, exerciseCount: Int)] {
        var seen = Set<String>()
        var result: [(serverId: String, name: String, exerciseCount: Int)] = []

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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Header
                        VStack(spacing: AppSpacing.xs) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.red)

                            Text("Delete \(program.name)?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text("This program has \(aiTemplates.count) AI-generated template\(aiTemplates.count == 1 ? "" : "s"). Select any you'd like to keep.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, AppSpacing.md)

                        // Template list
                        VStack(spacing: AppSpacing.xs) {
                            ForEach(aiTemplates, id: \.serverId) { template in
                                templateRow(template)
                            }
                        }

                        // Convenience buttons
                        HStack(spacing: AppSpacing.sm) {
                            Button {
                                keepTemplateIds = []
                            } label: {
                                Text("Delete All Templates")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .disabled(keepTemplateIds.isEmpty)

                            Button {
                                keepTemplateIds = Set(aiTemplates.map(\.serverId))
                            } label: {
                                Text("Keep All Templates")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(.bordered)
                            .disabled(keepTemplateIds.count == aiTemplates.count)
                        }
                    }
                    .padding(AppSpacing.md)
                }

                // Bottom action area
                VStack(spacing: AppSpacing.sm) {
                    Divider()

                    VStack(spacing: AppSpacing.xs) {
                        if !keepTemplateIds.isEmpty {
                            Text("Keeping \(keepTemplateIds.count) template\(keepTemplateIds.count == 1 ? "" : "s"), deleting \(aiTemplates.count - keepTemplateIds.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Deleting program and all \(aiTemplates.count) template\(aiTemplates.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button(role: .destructive) {
                            onConfirmDelete(Array(keepTemplateIds))
                        } label: {
                            if isDeletingProgram {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Delete Program")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.large)
                        .disabled(isDeletingProgram)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }

    // MARK: - Template Row

    private func templateRow(_ template: (serverId: String, name: String, exerciseCount: Int)) -> some View {
        let isKept = keepTemplateIds.contains(template.serverId)

        return Button {
            if isKept {
                keepTemplateIds.remove(template.serverId)
            } else {
                keepTemplateIds.insert(template.serverId)
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: isKept ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isKept ? .green : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("\(template.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(isKept ? "Keep" : "Delete")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isKept ? .green : .red)
            }
            .padding(AppSpacing.sm)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

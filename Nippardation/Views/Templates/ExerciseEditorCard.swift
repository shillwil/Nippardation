//
//  ExerciseEditorCard.swift
//  Nippardation
//
//  66pt exercise row in the workout editor: index square · name · "4 × 6-8 · rest 3:00" · chevron.
//  Tap opens the config sheet; the context menu moves or removes the exercise.
//

import SwiftUI

struct ExerciseEditorCard: View {

    let index: Int
    let exercise: TemplateEditorViewModel.EditableExercise
    var isLast: Bool = false
    let onConfigure: () -> Void
    let onDelete: () -> Void
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil

    var body: some View {
        Button(action: onConfigure) {
            HStack(spacing: VoidSpace.s3) {
                VoidAvatar(text: VoidFormat.pad2(index + 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.displayName)
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                    Text(summary)
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text2)
                        .lineLimit(1)
                }

                Spacer(minLength: VoidSpace.s2)

                VoidChevron()
            }
            .frame(height: VoidSize.listRow)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidRowButtonStyle())
        .overlay(alignment: .bottom) {
            if !isLast {
                VoidHairline()
            }
        }
        .contextMenu {
            if let onMoveUp {
                Button(action: onMoveUp) {
                    Label("Move up", systemImage: GapIcon.up)
                }
            }
            if let onMoveDown {
                Button(action: onMoveDown) {
                    Label("Move down", systemImage: GapIcon.down)
                }
            }
            Button(action: onConfigure) {
                Label("Configure", systemImage: VoidIcon.edit.systemName)
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Remove exercise", systemImage: VoidIcon.trash.systemName)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Configure sets, reps and rest")
    }

    // MARK: - Helpers

    /// "4 × 6-8 · rest 3:00 · 2 warmup · note"
    private var summary: String {
        var parts: [String] = []
        parts.append("\(exercise.workingSets) × \(exercise.targetReps.isEmpty ? "?" : exercise.targetReps)")
        parts.append("rest \(ExerciseConfigFormat.rest(exercise.restSeconds))")
        if exercise.warmupSets > 0 {
            parts.append("\(exercise.warmupSets) warmup")
        }
        if !exercise.notes.isEmpty {
            parts.append(exercise.notes)
        }
        return parts.joined(separator: VoidFormat.dot)
    }
}

/// Console formatting shared by the editor row and the config sheet.
enum ExerciseConfigFormat {
    /// 180 → "3:00", 90 → "1:30", 45 → "0:45"
    static func rest(_ seconds: Int) -> String {
        let total = max(0, seconds)
        return "\(total / 60):\(String(format: "%02d", total % 60))"
    }
}

/// SF Symbols the Void glyph set does not name yet.
private enum GapIcon {
    static let up = "arrow.up"
    static let down = "arrow.down"
}

// MARK: - Previews

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        VoidListPanel {
            ExerciseEditorCard(
                index: 0,
                exercise: TemplateEditorViewModel.EditableExercise(
                    orderIndex: 0,
                    exerciseServerId: "ex_001",
                    exerciseLibraryItem: MockExerciseRepository.sampleExercises[0],
                    warmupSets: 2,
                    workingSets: 4,
                    targetReps: "6-8",
                    restSeconds: 180,
                    notes: "Pause on the chest"
                ),
                onConfigure: {},
                onDelete: {}
            )
            ExerciseEditorCard(
                index: 1,
                exercise: TemplateEditorViewModel.EditableExercise(
                    orderIndex: 1,
                    exerciseServerId: "ex_005",
                    exerciseLibraryItem: MockExerciseRepository.sampleExercises[4],
                    warmupSets: 0,
                    workingSets: 3,
                    targetReps: "12-15",
                    restSeconds: 60,
                    notes: ""
                ),
                isLast: true,
                onConfigure: {},
                onDelete: {}
            )
        }
    }
}

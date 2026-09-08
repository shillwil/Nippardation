//
//  WorkoutPreviewView.swift
//  Nippardation
//
//  Preview Exercises: the read-only exercise list for a workout, pushed from Today.
//  Video carousel on top, then a list panel of exercises; tapping a row opens the
//  existing read-only exercise detail sheet (as the old ExercisesListView did).
//

import SwiftUI

struct WorkoutPreviewView: View {
    let template: Template

    @State private var readOnlyWorkout: TrackedWorkout
    @State private var selectedExercise: IdentifiableIndex?

    init(template: Template) {
        self.template = template
        _readOnlyWorkout = State(initialValue: Self.readOnlyWorkout(for: template))
    }

    /// Sorted the same way `WorkoutBuilder` sorts, so row indices match the read-only workout.
    private var exercises: [TemplateExercise] {
        template.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// "06 EXERCISES · ~55 MIN · 18 SETS"
    private var summary: String {
        let sets = template.totalWorkingSets + template.totalWarmupSets
        return VoidFormat.readout([
            VoidFormat.exercises(template.exerciseCount),
            template.exercises.isEmpty ? nil : VoidFormat.minutes(TodayViewModel.roundedMinutes(template.estimatedDurationMinutes)),
            sets > 0 ? "\(VoidFormat.pad2(sets)) sets" : nil
        ])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoidSpace.s4) {
                ExerciseVideoCarousel(template: template, title: nil)

                Text(summary)
                    .voidReadout()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, VoidSpace.insetText)

                if exercises.isEmpty {
                    VoidListPanel {
                        VoidPlaceholder(
                            eyebrow: "No exercises yet",
                            caption: "Add exercises to this workout from the Plan tab."
                        )
                    }
                } else {
                    VoidListPanel {
                        ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                            exerciseRow(exercise, index: index)
                            if index < exercises.count - 1 {
                                VoidHairline()
                            }
                        }
                    }
                }
            }
            .padding(.top, VoidSpace.s2)
            .padding(.bottom, VoidSpace.s6)
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .voidScreen()
        .sheet(item: $selectedExercise) { item in
            ActiveExerciseDetailView(
                workout: $readOnlyWorkout,
                showingExerciseDetail: Binding(
                    get: { selectedExercise != nil },
                    set: { if !$0 { selectedExercise = nil } }
                ),
                exerciseIndex: item.value,
                isReadOnly: true
            )
        }
    }

    // MARK: - Rows

    private func exerciseRow(_ exercise: TemplateExercise, index: Int) -> some View {
        Button {
            selectedExercise = IdentifiableIndex(id: index)
        } label: {
            HStack(spacing: VoidSpace.s3) {
                Text(VoidFormat.pad2(index + 1))
                    .voidEyebrowSm(VoidColor.text3)
                    .frame(width: 22, alignment: .leading)
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.exerciseLibraryItem?.name ?? "Exercise")
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                        .lineLimit(1)
                    Text(Self.prescription(for: exercise))
                        .voidEyebrowSm()
                        .lineLimit(1)
                }
                Spacer(minLength: VoidSpace.s2)
                VoidChevron()
            }
            .frame(height: VoidSize.listRow)
            .contentShape(Rectangle())
        }
        .buttonStyle(VoidRowButtonStyle())
    }

    /// "3 × 8–12 · 2 warm-up · 90 s rest" (the eyebrow style uppercases it).
    static func prescription(for exercise: TemplateExercise) -> String {
        let reps = (exercise.targetReps ?? "").trimmingCharacters(in: .whitespaces)
        let sets = reps.isEmpty
            ? "\(exercise.workingSets) sets"
            : "\(exercise.workingSets) × \(reps.replacingOccurrences(of: "-", with: "–"))"

        var parts: [String?] = [sets]
        if let warmups = exercise.warmupSets, warmups > 0 {
            parts.append("\(warmups) warm-up")
        }
        if let rest = exercise.restSeconds, rest > 0 {
            parts.append(rest >= 60 && rest % 60 == 0 ? "\(rest / 60) min rest" : "\(rest) s rest")
        }
        return VoidFormat.readout(parts)
    }

    // MARK: - Read-only workout for the detail sheet

    private static func readOnlyWorkout(for template: Template) -> TrackedWorkout {
        let workout = WorkoutBuilder.workout(from: template)
        let trackedExercises = workout.exercises.map { exercise in
            TrackedExercise(
                exerciseName: exercise.type.name,
                muscleGroups: exercise.type.muscleGroup.map { $0.rawValue },
                trackedSets: [],
                exerciseLibraryServerId: exercise.exerciseServerId
            )
        }
        return TrackedWorkout(
            date: Date(),
            workoutTemplate: workout.name,
            trackedExercises: trackedExercises
        )
    }
}

// MARK: - Preview

#Preview("Workout preview") {
    NavigationStack {
        WorkoutPreviewView(template: MockData.pushTemplate)
    }
    .withDependencies(.preview)
}

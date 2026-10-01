//
//  WorkoutPreviewView.swift
//  Nippardation
//
//  Preview Exercises: the read-only exercise list for a workout, pushed from Today.
//  A grouped list: the video carousel on top, then the exercises under a summary header;
//  tapping a row opens the existing read-only exercise detail sheet (as the old
//  ExercisesListView did). A workout with no exercises shows the standard empty state.
//

import SwiftUI

struct WorkoutPreviewView: View {
    let template: Template

    @State private var readOnlyWorkout: TrackedWorkout
    @State private var selectedExercise: IdentifiableIndex?
    /// The row number's column grows with the text size, so "03" never breaks onto two lines.
    @ScaledMetric private var numberColumnWidth: CGFloat = 22

    init(template: Template) {
        self.template = template
        _readOnlyWorkout = State(initialValue: Self.readOnlyWorkout(for: template))
    }

    /// Sorted the same way `WorkoutBuilder` sorts, so row indices match the read-only workout.
    private var exercises: [TemplateExercise] {
        template.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Mirrors `ExerciseVideoCarousel`'s filter: it only draws cards for exercises with a
    /// library item, and draws nothing otherwise, so skip its row rather than leave a gap.
    private var hasVideoCards: Bool {
        template.exercises.contains { $0.exerciseLibraryItem != nil }
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
        List {
            if !exercises.isEmpty {
                if hasVideoCards {
                    Section {
                        ExerciseVideoCarousel(template: template, title: nil)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }

                Section {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        exerciseRow(exercise, index: index)
                            .listRowBackground(VoidColor.panel)
                            .listRowSeparatorTint(VoidColor.hairline)
                    }
                } header: {
                    Text(summary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if exercises.isEmpty {
                ContentUnavailableView(
                    "No exercises yet",
                    systemImage: VoidIcon.barbell.systemName,
                    description: Text("Add exercises to this workout from the Plan tab.")
                )
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
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
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Rows

    /// Opens a sheet, so no disclosure chevron: the list's own highlight is the press state.
    private func exerciseRow(_ exercise: TemplateExercise, index: Int) -> some View {
        Button {
            selectedExercise = IdentifiableIndex(id: index)
        } label: {
            HStack(spacing: VoidSpace.s3) {
                Text(VoidFormat.pad2(index + 1))
                    .voidEyebrowSm(VoidColor.text3)
                    .fixedSize()
                    .frame(minWidth: numberColumnWidth, alignment: .leading)
                VStack(alignment: .leading, spacing: 3) {
                    // Shrinks toward 70% to stay on one line, then wraps onto a second.
                    ShrinkThenWrapText(exercise.displayName)
                        .font(VoidFont.bodyStrong)
                        .foregroundStyle(VoidColor.text)
                    ShrinkThenWrapText(Self.prescription(for: exercise))
                        .voidEyebrowSm()
                }
                Spacer(minLength: VoidSpace.s2)
            }
        }
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

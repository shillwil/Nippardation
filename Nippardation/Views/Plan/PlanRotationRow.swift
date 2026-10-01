//
//  PlanRotationRow.swift
//  Nippardation
//
//  One row of the Plan rotation, at least 94pt: [52pt tile] 14 [eyebrow-sm over word]. A long
//  workout name wraps onto a second line (shrinking as needed) rather than truncating.
//  The tile carries the state (done / skipped / next / later); the up-next row also draws the 3×36 plasma
//  mark flush to the row's leading edge. The list owns the rest: separators, and the system disclosure
//  chevron on rows that open their workout (a NavigationLink). Place the row with zero list-row insets.
//

import SwiftUI

struct PlanRotationRow: View {
    let row: RotationRow

    private var eyebrowColor: Color {
        switch row.state {
        case .done, .skipped: return VoidColor.text3
        case .next: return VoidColor.warning
        case .later: return VoidColor.text2
        }
    }

    private var wordColor: Color {
        switch row.state {
        case .done, .skipped: return VoidColor.text3
        case .next: return VoidColor.text
        case .later: return VoidColor.textSoft
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 14) {
                WorkoutTile(glyph: row.glyph, state: row.state)

                VStack(alignment: .leading, spacing: 6) {
                    Text(row.eyebrow)
                        .voidEyebrowSm(eyebrowColor)
                        .lineLimit(1)
                    // Two lines, and a 0.5 floor: Michroma is wide, and at 0.7 a name like
                    // CHEST/TRICEPS FOCUS still overruns a 6.1-inch row by a few points.
                    Text(row.word)
                        .voidWordRow(wordColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                }

                Spacer(minLength: VoidSpace.s2)
            }
            .padding(.horizontal, VoidSpace.insetText)
            // Room above and below once the word wraps; a one-line row still comes out at 94pt.
            .padding(.vertical, VoidSpace.s3)
            .frame(maxWidth: .infinity)
            .frame(minHeight: VoidSize.row)

            if row.isUpNext {
                UpNextMark()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
    }
}

extension RotationRow {
    /// "Push, Tuesday, up next"
    var accessibilityLabel: String {
        let status: String
        switch state {
        case .done: status = "done"
        case .skipped: status = "skipped"
        case .next: status = "up next"
        case .later: status = "later"
        }
        return "\(word), \(weekday.capitalized), \(status)"
    }
}

// MARK: - Previews

#Preview("Rows") {
    let program = MockProgramRepository.samplePrograms[0]
    let templates = MockTemplateRepository.sampleTemplates
    let done = TrackedWorkout(date: Date(), workoutTemplate: "Push Day", trackedExercises: [], isCompleted: true)
    let skipped = program.workouts.sorted { $0.dayNumber < $1.dayNumber }.dropFirst().first.map {
        [SkippedWorkout(programServerId: program.serverId, workoutId: $0.id, templateServerId: $0.templateServerId)]
    } ?? []
    let rows = PlanRotationBuilder.rows(
        for: program,
        templates: templates,
        completedWorkouts: [done],
        skippedWorkouts: skipped
    )

    return List {
        ForEach(rows) { row in
            PlanRotationRow(row: row)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(VoidColor.hairline)
        }
    }
    .listStyle(.plain)
    .voidScreen()
}

//
//  PlanRotationRow.swift
//  Nippardation
//
//  One 94pt row of the Plan rotation: [52pt tile] 14 [eyebrow-sm over word] … [16pt chevron].
//  The tile carries the state (done / next / later); the up-next row also draws the 3×36 plasma
//  mark flush to the left screen edge. Separators are drawn by the list, not the row.
//

import SwiftUI

struct PlanRotationRow: View {
    let row: RotationRow
    /// Hidden when the row has nothing to open (its workout could not be resolved).
    var showsChevron: Bool = true

    private var eyebrowColor: Color {
        switch row.state {
        case .done: return VoidColor.text3
        case .next: return VoidColor.warning
        case .later: return VoidColor.text2
        }
    }

    private var wordColor: Color {
        switch row.state {
        case .done: return VoidColor.text3
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
                    Text(row.word)
                        .voidWordRow(wordColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                Spacer(minLength: VoidSpace.s2)

                if !row.isDone && showsChevron {
                    VoidChevron(color: row.isUpNext ? VoidColor.plasma : VoidColor.text3)
                }
            }
            .padding(.horizontal, VoidSpace.insetText)
            .frame(maxWidth: .infinity)
            .frame(height: VoidSize.row)

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
    let rows = PlanRotationBuilder.rows(for: program, templates: templates, completedWorkouts: [done])

    return ZStack {
        VoidColor.hull.ignoresSafeArea()
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                PlanRotationRow(row: row)
                if index < rows.count - 1 {
                    VoidHairline()
                }
            }
        }
    }
}

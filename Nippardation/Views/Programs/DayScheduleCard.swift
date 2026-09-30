//
//  DayScheduleCard.swift
//  Nippardation
//
//  One day of the schedule builder, as a list row: tile, eyebrow, workout name (or a prompt),
//  rest-day toggle.
//

import SwiftUI

struct DayScheduleCard: View {
    /// Day of week, 0 = Monday.
    let dayNumber: Int
    /// Position in the rotation, 0-based. Shown as DAY 01 when given.
    var dayIndex: Int? = nil
    let templateName: String?
    let exerciseCount: Int?
    let isRest: Bool
    let onSelectTemplate: () -> Void
    let onToggleRest: () -> Void

    private var dayLabel: String {
        guard dayNumber >= 0 && dayNumber < VoidFormat.weekStripLabels.count else { return "Day" }
        return VoidFormat.weekStripLabels[dayNumber]
    }

    private var eyebrow: String {
        if let dayIndex {
            return VoidFormat.readout([dayLabel, "DAY \(VoidFormat.pad2(dayIndex + 1))"])
        }
        return dayLabel
    }

    private var tile: some View {
        Group {
            if isRest {
                WorkoutTile(glyph: .rest, ghost: true)
            } else if let templateName {
                WorkoutTile(glyph: VoidIcon.workoutGlyph(for: templateName))
            } else {
                WorkoutTile(glyph: .plus)
            }
        }
    }

    /// The toggle reports its new state; the owner flips the day, so the card only relays the tap.
    private var restBinding: Binding<Bool> {
        Binding(
            get: { isRest },
            set: { _ in onToggleRest() }
        )
    }

    /// Two controls share the row. Each carries a non-automatic button style, so a tap fires only
    /// the one under the finger rather than every button in the list row.
    var body: some View {
        HStack(spacing: 14) {
            Button(action: onSelectTemplate) {
                HStack(spacing: 14) {
                    tile

                    VStack(alignment: .leading, spacing: VoidSpace.s1) {
                        Text(eyebrow).voidEyebrowSm(isRest ? VoidColor.text3 : VoidColor.text2)

                        if isRest {
                            Text("Rest day")
                                .font(VoidFont.bodyStrong)
                                .foregroundStyle(VoidColor.text2)
                                .lineLimit(1)
                        } else if let templateName {
                            Text(templateName)
                                .font(VoidFont.bodyStrong)
                                .foregroundStyle(VoidColor.text)
                                .lineLimit(1)
                            if let exerciseCount {
                                Text(VoidFormat.exercises(exerciseCount)).voidReadout()
                            }
                        } else {
                            Text("Select workout")
                                .font(VoidFont.bodyStrong)
                                .foregroundStyle(VoidColor.text2)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isRest)
            .accessibilityLabel(accessibilityText)
            .accessibilityHint(isRest ? "" : "Choose a workout for this day")

            // System toggle button in the prominent style: on fills with the tint, off is the bare
            // glyph. The tint is the quiet panel-2 well this control always used (not a second plasma
            // action), and the glyph colour is set per state because the style's default white label
            // would vanish on that light fill. Large control size keeps the hit target about 60 × 50pt
            // in both states. (Bordered would fill the off state grey and leave on a faint wash;
            // borderless shrinks the off hit target to the glyph.)
            Toggle(isOn: restBinding) {
                Label("Rest day", systemImage: VoidIcon.rest.systemName)
                    .foregroundStyle(isRest ? VoidColor.text : VoidColor.text2)
            }
            .toggleStyle(.button)
            .buttonStyle(.borderedProminent)
            .labelStyle(.iconOnly)
            .controlSize(.large)
            .buttonBorderShape(.roundedRectangle(radius: VoidRadius.control))
            .tint(VoidColor.panel2)
        }
    }

    private var accessibilityText: String {
        if isRest { return "\(dayLabel), rest day" }
        if let templateName { return "\(dayLabel), \(templateName)" }
        return "\(dayLabel), no workout yet"
    }
}

#Preview {
    List {
        Section {
            DayScheduleCard(
                dayNumber: 0, dayIndex: 0, templateName: "Push Day",
                exerciseCount: 7, isRest: false,
                onSelectTemplate: {}, onToggleRest: {}
            )
            DayScheduleCard(
                dayNumber: 2, dayIndex: 1, templateName: nil,
                exerciseCount: nil, isRest: false,
                onSelectTemplate: {}, onToggleRest: {}
            )
            DayScheduleCard(
                dayNumber: 4, dayIndex: 2, templateName: nil,
                exerciseCount: nil, isRest: true,
                onSelectTemplate: {}, onToggleRest: {}
            )
        }
        .wizardFormRows()
    }
    .listStyle(.insetGrouped)
    .voidScreen()
}

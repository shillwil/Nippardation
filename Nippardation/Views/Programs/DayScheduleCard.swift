//
//  DayScheduleCard.swift
//  Nippardation
//
//  One day of the schedule builder: tile, eyebrow, workout name (or a prompt), rest toggle.
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
                                .foregroundStyle(VoidColor.plasma)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(VoidPlainButtonStyle())
            .disabled(isRest)
            .accessibilityLabel(accessibilityText)
            .accessibilityHint(isRest ? "" : "Choose a workout for this day")

            // 32pt control chrome drawn inside a 44pt label: a frame outside a Button only pads layout,
            // the tappable region is the label, so the hit target has to be the label itself.
            Button(action: onToggleRest) {
                ZStack {
                    RoundedRectangle(cornerRadius: VoidRadius.control, style: .continuous)
                        .fill(isRest ? VoidColor.panel2 : VoidColor.panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: VoidRadius.control, style: .continuous)
                                .strokeBorder(VoidColor.hairline2, lineWidth: 1)
                        )
                        .frame(width: VoidSize.control, height: VoidSize.control)

                    Image(systemName: VoidIcon.rest.systemName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isRest ? VoidColor.text : VoidColor.text2)
                }
                .frame(width: VoidSize.hitMin, height: VoidSize.hitMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(VoidPlainButtonStyle())
            .accessibilityLabel(isRest ? "Make a training day" : "Make a rest day")
        }
        .padding(14)
        .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2)
    }

    private var accessibilityText: String {
        if isRest { return "\(dayLabel), rest day" }
        if let templateName { return "\(dayLabel), \(templateName)" }
        return "\(dayLabel), no workout yet"
    }
}

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        VStack(spacing: 10) {
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
        .padding(VoidSpace.insetCard)
    }
}

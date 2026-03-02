//
//  DayScheduleCard.swift
//  Nippardation
//
//  Day card for the weekly schedule builder in the program wizard
//

import SwiftUI

struct DayScheduleCard: View {
    let dayNumber: Int
    let templateName: String?
    let exerciseCount: Int?
    let isRest: Bool
    let onSelectTemplate: () -> Void
    let onToggleRest: () -> Void

    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Day circle
            VStack(spacing: AppSpacing.xxs) {
                Text(dayNumber >= 0 && dayNumber < dayNames.count ? dayNames[dayNumber] : "Day")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Circle()
                    .fill(circleColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: circleIcon)
                            .font(.caption)
                            .foregroundColor(.white)
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if isRest {
                    Text("Rest Day")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                } else if let name = templateName {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let count = exerciseCount {
                        Text("\(count) exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: onSelectTemplate) {
                        Text("Select Template")
                            .font(.subheadline)
                            .foregroundColor(.appTheme)
                    }
                }
            }

            Spacer()

            // Rest toggle
            Button {
                onToggleRest()
            } label: {
                Image(systemName: isRest ? "moon.fill" : "moon")
                    .foregroundColor(isRest ? .purple : .secondary)
            }
        }
        .padding(AppSpacing.sm)
        .background(isRest ? Color(.tertiarySystemBackground) : Color(.secondarySystemBackground))
        .cornerRadius(AppCornerRadius.medium)
        .onTapGesture {
            if !isRest && templateName == nil {
                onSelectTemplate()
            }
        }
    }

    private var circleColor: Color {
        if isRest { return .gray }
        if templateName != nil { return .appTheme }
        return .secondary.opacity(0.5)
    }

    private var circleIcon: String {
        if isRest { return "moon.fill" }
        if templateName != nil { return "checkmark" }
        return "plus"
    }
}

#Preview {
    VStack(spacing: AppSpacing.sm) {
        DayScheduleCard(
            dayNumber: 0, templateName: "Push Day",
            exerciseCount: 7, isRest: false,
            onSelectTemplate: {}, onToggleRest: {}
        )
        DayScheduleCard(
            dayNumber: 1, templateName: nil,
            exerciseCount: nil, isRest: false,
            onSelectTemplate: {}, onToggleRest: {}
        )
        DayScheduleCard(
            dayNumber: 2, templateName: nil,
            exerciseCount: nil, isRest: true,
            onSelectTemplate: {}, onToggleRest: {}
        )
    }
    .padding()
}

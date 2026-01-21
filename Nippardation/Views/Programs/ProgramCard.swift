//
//  ProgramCard.swift
//  Nippardation
//
//  Card component for displaying a program in a list
//

import SwiftUI

struct ProgramCard: View {

    let program: Program

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(program.name)
                    .font(.headline)

                Spacer()

                if program.isActive {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(4)
                }

                if program.isAiGenerated {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.caption)
                }
            }

            if let description = program.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label(program.frequencyString, systemImage: "calendar")

                Label(program.durationString, systemImage: "clock")

                if program.timesCompleted > 0 {
                    Label("\(program.timesCompleted)x", systemImage: "checkmark.circle")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Progress indicator for active program
            if program.isActive && !program.isIndefinite {
                VStack(alignment: .leading, spacing: 2) {
                    ProgressView(value: program.progress)
                        .tint(.green)

                    Text("Day \(program.currentDayIndex + 1) of \(program.daysPerWeek)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

#Preview("Active Program") {
    List {
        ProgramCard(program: MockProgramRepository.samplePrograms[0])
    }
}

#Preview("Inactive Program") {
    List {
        ProgramCard(program: MockProgramRepository.samplePrograms[1])
    }
}

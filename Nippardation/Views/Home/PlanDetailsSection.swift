//
//  PlanDetailsSection.swift
//  Nippardation
//
//  Shows active program info and next workout on the home dashboard
//

import SwiftUI

struct PlanDetailsSection: View {
    let program: Program?
    let nextWorkout: ProgramWorkout?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Active Plan")

            if let program {
                NavigationLink(destination: ProgramDetailView(programServerId: program.serverId)) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(program.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack(spacing: AppSpacing.sm) {
                                Label(program.frequencyString, systemImage: "calendar")
                                Label(program.durationString, systemImage: "clock")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)

                            if !program.isIndefinite {
                                ProgressView(value: program.progress)
                                    .tint(.green)
                                    .padding(.top, AppSpacing.xxs)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(AppSpacing.md)
                    .cardStyle()
                }
            } else {
                NavigationLink(destination: ProgramListView()) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("No active plan")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Tap to browse programs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(AppSpacing.md)
                    .cardStyle(hasBorder: true)
                }
            }
        }
    }
}

#Preview("With Program") {
    NavigationStack {
        PlanDetailsSection(
            program: MockProgramRepository.samplePrograms[0],
            nextWorkout: MockProgramRepository.samplePrograms[0].currentWorkout
        )
        .padding()
        .withDependencies(.preview)
    }
}

#Preview("No Program") {
    NavigationStack {
        PlanDetailsSection(program: nil, nextWorkout: nil)
            .padding()
    }
}

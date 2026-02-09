//
//  MuscleAnalysisChart.swift
//  Nippardation
//
//  Donut chart showing muscle group distribution for a template
//

import SwiftUI

struct MuscleAnalysisChart: View {
    let distribution: [(MuscleGroup, Double)]

    private var totalSets: Double {
        distribution.reduce(0) { $0 + $1.1 }
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            SectionHeader(title: "Muscle Analysis")

            if distribution.isEmpty {
                emptyState
            } else {
                HStack(spacing: AppSpacing.lg) {
                    donutChart
                        .frame(width: 120, height: 120)

                    legend
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }

    // MARK: - Donut Chart

    private var donutChart: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                Circle()
                    .trim(from: segment.start, to: segment.end)
                    .stroke(segment.color, style: StrokeStyle(lineWidth: 16, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text("\(Int(totalSets))")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("sets")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Legend

    private var legend: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(Array(distribution.prefix(5).enumerated()), id: \.offset) { _, item in
                HStack(spacing: AppSpacing.xs) {
                    Circle()
                        .fill(colorForMuscle(item.0))
                        .frame(width: 8, height: 8)

                    Text(item.0.rawValue.capitalized)
                        .font(.caption)

                    Spacer()

                    Text("\(Int(item.1)) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if distribution.count > 5 {
                Text("+\(distribution.count - 5) more")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: "chart.pie")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Add exercises to see muscle analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Segment Calculation

    private struct ChartSegment {
        let start: CGFloat
        let end: CGFloat
        let color: Color
    }

    private var segments: [ChartSegment] {
        guard totalSets > 0 else { return [] }

        var result: [ChartSegment] = []
        var current: CGFloat = 0

        for item in distribution {
            let fraction = CGFloat(item.1 / totalSets)
            let segment = ChartSegment(
                start: current,
                end: current + fraction,
                color: colorForMuscle(item.0)
            )
            result.append(segment)
            current += fraction
        }

        return result
    }
}

// MARK: - Muscle Group Colors

func colorForMuscle(_ muscle: MuscleGroup) -> Color {
    switch muscle {
    case .chest: return .blue
    case .back: return .green
    case .shoulders: return .orange
    case .biceps: return .purple
    case .triceps: return .pink
    case .quads: return .teal
    case .hamstrings: return .indigo
    case .glutes: return .red
    case .calves: return .mint
    case .abs: return .yellow
    }
}

#Preview {
    MuscleAnalysisChart(distribution: [
        (.chest, 12),
        (.shoulders, 6),
        (.triceps, 6),
        (.back, 3)
    ])
    .padding()
}

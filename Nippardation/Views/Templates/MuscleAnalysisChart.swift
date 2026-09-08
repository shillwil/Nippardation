//
//  MuscleAnalysisChart.swift
//  Nippardation
//
//  Muscle split for a workout: one bar per muscle group, working sets per muscle.
//  Largest bar in plasma, the rest in text-3. Flat fills, no gradients.
//

import SwiftUI

struct MuscleAnalysisChart: View {
    let distribution: [(MuscleGroup, Double)]

    private static let maxRows = 6

    private var totalSets: Double {
        distribution.reduce(0) { $0 + $1.1 }
    }

    private var maxSets: Double {
        distribution.map { $0.1 }.max() ?? 0
    }

    private var shown: [(MuscleGroup, Double)] {
        Array(distribution.prefix(Self.maxRows))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VoidSpace.s3) {
            HStack {
                Text("Muscle split")
                    .voidEyebrowSm()
                Spacer()
                Text("\(VoidFormat.pad2(Int(totalSets.rounded()))) sets")
                    .voidEyebrowSm()
            }

            if distribution.isEmpty {
                VoidPlaceholder(eyebrow: "No sets yet", caption: "Add exercises to see the split.")
            } else {
                VStack(spacing: VoidSpace.s2) {
                    ForEach(Array(shown.enumerated()), id: \.offset) { index, item in
                        MuscleBarRow(
                            name: item.0.rawValue,
                            fraction: maxSets > 0 ? item.1 / maxSets : 0,
                            sets: item.1,
                            isLargest: index == 0
                        )
                    }
                }

                if distribution.count > shown.count {
                    Text("+\(distribution.count - shown.count) more")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text3)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .voidPanel()
    }
}

// MARK: - Bar row

private struct MuscleBarRow: View {
    let name: String
    let fraction: Double
    let sets: Double
    let isLargest: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(name)
                .voidEyebrowSm(isLargest ? VoidColor.text : VoidColor.text2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 84, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(VoidColor.track)
                    Rectangle()
                        .fill(isLargest ? VoidColor.plasma : VoidColor.text3)
                        .frame(width: max(3, geo.size.width * min(max(fraction, 0), 1)))
                }
            }
            .frame(height: 6)

            Text(setsLabel)
                .voidReadout(isLargest ? VoidColor.text : VoidColor.text2)
                .frame(width: 36, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name): \(setsLabel) sets")
    }

    private var setsLabel: String {
        if sets.rounded() == sets {
            return VoidFormat.pad2(Int(sets))
        }
        return String(format: "%.1f", sets)
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        VoidColor.hull.ignoresSafeArea()
        VStack(spacing: 16) {
            MuscleAnalysisChart(distribution: [
                (.chest, 12),
                (.shoulders, 6),
                (.triceps, 6),
                (.back, 3)
            ])
            MuscleAnalysisChart(distribution: [])
        }
        .padding(.horizontal, 16)
    }
}

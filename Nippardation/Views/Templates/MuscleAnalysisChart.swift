//
//  MuscleAnalysisChart.swift
//  Nippardation
//
//  Muscle split for a workout: a Swift Charts bar per muscle group, working sets per muscle.
//  Largest bar in plasma, the rest in text-3. Flat fills, no gradients.
//

import SwiftUI
import Charts

struct MuscleAnalysisChart: View {
    let distribution: [(MuscleGroup, Double)]

    private static let maxRows = 6
    /// Height of one muscle's band in the chart. Grows with Dynamic Type like the labels and set
    /// counts (custom fonts, which scale with body), so they keep clear of the next band.
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 24

    private var totalSets: Double {
        distribution.reduce(0) { $0 + $1.1 }
    }

    private var maxSets: Double {
        distribution.map { $0.1 }.max() ?? 0
    }

    /// The largest groups, biggest first (the distribution arrives sorted).
    private var bars: [MuscleBar] {
        distribution.prefix(Self.maxRows).enumerated().map { index, item in
            MuscleBar(muscle: item.0, sets: item.1, isLargest: index == 0)
        }
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
                chart

                if distribution.count > Self.maxRows {
                    Text("+\(distribution.count - Self.maxRows) more")
                        .font(VoidFont.caption2)
                        .foregroundStyle(VoidColor.text3)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .voidPanel()
    }

    private var chart: some View {
        let bars = self.bars
        let largestName = bars.first?.name
        // Headroom past the longest bar so its set count fits beside it.
        let xUpperBound = max(maxSets * 1.25, 1)

        return Chart(bars) { bar in
            BarMark(
                x: .value("Sets", bar.sets),
                y: .value("Muscle", bar.name),
                height: .fixed(6)
            )
            .foregroundStyle(bar.isLargest ? VoidColor.plasma : VoidColor.text3)
            .annotation(position: .trailing, alignment: .leading, spacing: VoidSpace.s2) {
                Text(bar.setsLabel)
                    .voidReadout(bar.isLargest ? VoidColor.text : VoidColor.text2)
            }
            .accessibilityLabel(Text(bar.name.capitalized))
            .accessibilityValue(Text("\(bar.setsLabel) sets"))
        }
        .chartXScale(domain: 0...xUpperBound)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let name = value.as(String.self) {
                        Text(name)
                            .voidEyebrowSm(name == largestName ? VoidColor.text : VoidColor.text2)
                    }
                }
            }
        }
        .frame(height: CGFloat(bars.count) * rowHeight)
    }
}

// MARK: - Bar

private struct MuscleBar: Identifiable {
    let muscle: MuscleGroup
    let sets: Double
    let isLargest: Bool

    var id: MuscleGroup { muscle }
    var name: String { muscle.rawValue }

    /// Whole counts zero-padded ("06"); split sets keep one decimal ("2.5").
    var setsLabel: String {
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

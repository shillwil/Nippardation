//
//  CircularProgressView.swift
//  Nippardation
//
//  Reusable ring progress indicator
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var trackColor: Color = Color.secondary.opacity(0.2)
    var progressColor: Color = .appTheme
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Center percentage text
            Text("\(Int(min(progress, 1.0) * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(width: size, height: size)
    }
}

#Preview("Progress States") {
    HStack(spacing: AppSpacing.lg) {
        CircularProgressView(progress: 0.0)
        CircularProgressView(progress: 0.35, progressColor: .orange)
        CircularProgressView(progress: 0.75, progressColor: .green)
        CircularProgressView(progress: 1.0, progressColor: .blue, size: 80)
    }
    .padding()
}

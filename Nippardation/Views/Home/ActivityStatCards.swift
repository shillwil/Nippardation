//
//  ActivityStatCards.swift
//  Nippardation
//
//  Horizontal ScrollView of stat cards for the home dashboard
//

import SwiftUI

struct ActivityStatCards: View {
    let workoutsThisWeek: Int
    let totalVolume: String
    let weeklyConsistency: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                StatCard(
                    icon: "flame.fill",
                    value: "\(workoutsThisWeek)",
                    label: "This Week",
                    iconColor: .orange
                )
                .frame(width: 140)

                StatCard(
                    icon: "scalemass.fill",
                    value: totalVolume,
                    label: "Total Volume",
                    iconColor: .blue
                )
                .frame(width: 140)

                StatCard(
                    icon: "chart.bar.fill",
                    value: "\(weeklyConsistency)%",
                    label: "Consistency",
                    iconColor: .green
                )
                .frame(width: 140)
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
}

#Preview {
    ActivityStatCards(
        workoutsThisWeek: 4,
        totalVolume: "12.4K lbs",
        weeklyConsistency: 85
    )
}

//
//  HistoryPlaceholderView.swift
//  Nippardation
//
//  Placeholder for the History tab (coming soon)
//

import SwiftUI

struct HistoryPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "clock.arrow.circlepath",
            description: Text("Your full workout history will appear here in a future update.")
        )
        .navigationTitle("History")
    }
}

#Preview {
    NavigationStack {
        HistoryPlaceholderView()
    }
}

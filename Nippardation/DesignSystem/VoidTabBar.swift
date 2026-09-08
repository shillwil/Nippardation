//
//  VoidTabBar.swift
//  Nippardation
//
//  Tab identity and app-wide navigation state for the three tabs: Today · Plan · Progress.
//  The bar itself is the standard SwiftUI/UIKit tab bar, built in `MainTabView`.
//

import SwiftUI

/// The three bottom tabs.
enum AppTab: String, CaseIterable, Hashable, Identifiable {
    case today
    case plan
    case progress

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: return "Today"
        case .plan: return "Plan"
        case .progress: return "Progress"
        }
    }

    var icon: VoidIcon {
        switch self {
        case .today: return .tabToday
        case .plan: return .tabPlan
        case .progress: return .tabProgress
        }
    }
}

/// App-wide navigation state shared through the environment so any screen can switch tabs.
@MainActor
final class AppNavigation: ObservableObject {
    @Published var selectedTab: AppTab = .today

    init() {
        #if DEBUG
        if let tab = VoidPreviewMode.initialTab { selectedTab = tab }
        #endif
    }

    /// Bumps whenever something that Today/Plan should reload from changed (plan activated, import, etc.).
    @Published var planRevision: Int = 0

    func show(_ tab: AppTab) {
        selectedTab = tab
    }

    func planDidChange() {
        planRevision &+= 1
    }
}

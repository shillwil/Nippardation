//
//  MainTabView.swift
//  Nippardation
//
//  Root of the authenticated experience: Today · Plan · Progress in the standard iOS tab bar.
//  Also lands incoming share links in the Plan received sheet.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @StateObject private var navigation = AppNavigation()
    @ObservedObject private var receivedPlans = ReceivedPlansStore.shared
    @State private var receivedToken: ShareTokenItem?

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            Tab(AppTab.today.label, systemImage: AppTab.today.icon.systemName, value: .today) {
                NavigationStack {
                    TodayView()
                }
            }

            Tab(AppTab.plan.label, systemImage: AppTab.plan.icon.systemName, value: .plan) {
                NavigationStack {
                    PlanView()
                }
            }
            .badge(receivedPlans.hasUnread ? 1 : 0)

            Tab(AppTab.progress.label, systemImage: AppTab.progress.icon.systemName, value: .progress) {
                NavigationStack {
                    ProgressTabView()
                }
            }
        }
        .background(VoidColor.hull.ignoresSafeArea())
        .tint(VoidColor.plasma)
        .preferredColorScheme(nil)
        .environmentObject(navigation)
        .environmentBanner()
        .onAppear {
            paintWindowBackground()
            consumePendingToken()
        }
        .onChange(of: deepLinkRouter.pendingShareToken) { _, _ in
            consumePendingToken()
        }
        .sheet(item: $receivedToken) { item in
            PlanReceivedSheet(token: item.id) {
                receivedToken = nil
            }
            .environmentObject(navigation)
            .onDisappear {
                if deepLinkRouter.pendingShareToken == item.id {
                    deepLinkRouter.clearPendingToken()
                }
            }
        }
    }

    /// The window shows behind the scaled-down presenter under a `.large` sheet and during
    /// full-screen-cover transitions; paint it hull so light mode does not show black there.
    private func paintWindowBackground() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows {
            window.backgroundColor = VoidColor.hullUIColor
        }
    }

    private func consumePendingToken() {
        guard let token = deepLinkRouter.pendingShareToken else { return }
        receivedToken = ShareTokenItem(id: token)
    }
}

/// Identifiable wrapper so a share token can drive `.sheet(item:)`.
struct ShareTokenItem: Identifiable, Equatable {
    let id: String
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager.shared)
        .environmentObject(DeepLinkRouter.shared)
        .withDependencies(.preview)
}

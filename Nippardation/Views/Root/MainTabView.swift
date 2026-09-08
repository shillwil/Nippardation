//
//  MainTabView.swift
//  Nippardation
//
//  Root of the authenticated experience: Today · Plan · Progress behind the floating Void tab bar.
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
            NavigationStack {
                TodayView()
            }
            .voidTabBarClearance()
            .toolbar(.hidden, for: .tabBar)
            .tag(AppTab.today)

            NavigationStack {
                PlanView()
            }
            .voidTabBarClearance()
            .toolbar(.hidden, for: .tabBar)
            .tag(AppTab.plan)

            NavigationStack {
                ProgressTabView()
            }
            .voidTabBarClearance()
            .toolbar(.hidden, for: .tabBar)
            .tag(AppTab.progress)
        }
        .voidTabBar(selection: $navigation.selectedTab, showsPlanDot: receivedPlans.hasUnread)
        .background(VoidColor.hull.ignoresSafeArea())
        .tint(VoidColor.plasma)
        .preferredColorScheme(nil)
        .environmentObject(navigation)
        .environmentBanner()
        .onAppear {
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

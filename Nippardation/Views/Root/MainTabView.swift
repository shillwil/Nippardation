//
//  MainTabView.swift
//  Nippardation
//
//  Root view wrapping the authenticated experience in a 5-tab TabView
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tag(AppTab.home)
            .tabItem {
                Label(AppTab.home.label, systemImage: AppTab.home.icon)
            }

            NavigationStack {
                ProgramListView()
            }
            .tag(AppTab.programs)
            .tabItem {
                Label(AppTab.programs.label, systemImage: AppTab.programs.icon)
            }

            NavigationStack {
                TemplateListView()
            }
            .tag(AppTab.templates)
            .tabItem {
                Label(AppTab.templates.label, systemImage: AppTab.templates.icon)
            }

            NavigationStack {
                HistoryPlaceholderView()
            }
            .tag(AppTab.history)
            .tabItem {
                Label(AppTab.history.label, systemImage: AppTab.history.icon)
            }

            NavigationStack {
                ProfilePlaceholderView()
            }
            .tag(AppTab.profile)
            .tabItem {
                Label(AppTab.profile.label, systemImage: AppTab.profile.icon)
            }
        }
        .tint(Color.appTheme)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager.shared)
}

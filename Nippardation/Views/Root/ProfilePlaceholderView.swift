//
//  ProfilePlaceholderView.swift
//  Nippardation
//
//  Profile tab with user info and sign out (relocated from HomeView toolbar)
//

import SwiftUI

struct ProfilePlaceholderView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var error: Error?
    @State private var showErrorAlert = false

    var body: some View {
        List {
            Section {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.appTheme)

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(authManager.backendUser?.displayName ?? "User")
                            .font(.headline)

                        if let email = authManager.user?.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.xs)
            }

            Section {
                Button(role: .destructive) {
                    signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Profile")
        .alert("Sign Out Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(error?.localizedDescription ?? "An unknown error occurred")
        }
    }

    private func signOut() {
        do {
            try authManager.signOut()
        } catch {
            self.error = error
            showErrorAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        ProfilePlaceholderView()
            .environmentObject(AuthManager.shared)
    }
}

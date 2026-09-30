//
//  AccountView.swift
//  Nippardation
//
//  Account / settings: who is signed in, and sign out. Reached from the ··· menu on Plan.
//  A grouped list on the hull, with the app version under Sign out.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var error: Error?
    @State private var showErrorAlert = false

    private var displayName: String {
        if let name = authManager.backendUser?.displayName, !name.isEmpty { return name }
        if let handle = authManager.backendUser?.handle, !handle.isEmpty { return handle }
        return "User"
    }

    private var email: String? {
        authManager.user?.email ?? authManager.backendUser?.email
    }

    /// "Version 1.2 (34)" from the bundle.
    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: VoidSpace.s3) {
                    VoidAvatar(text: VoidFormat.initials(displayName))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName)
                            .font(VoidFont.bodyStrong)
                            .foregroundStyle(VoidColor.text)
                            .lineLimit(1)
                        if let email {
                            Text(email)
                                .font(VoidFont.caption2)
                                .foregroundStyle(VoidColor.text2)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                .listRowBackground(VoidColor.panel)
            } header: {
                Text("Signed in as")
            }

            Section {
                Button("Sign out", role: .destructive) {
                    signOut()
                }
                .listRowBackground(VoidColor.panel)
            } footer: {
                Text(versionString)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .voidScreen()
        .alert("Sign out error", isPresented: $showErrorAlert) {
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
        AccountView()
            .environmentObject(AuthManager.shared)
    }
    .withDependencies(.preview)
}

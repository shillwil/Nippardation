//
//  AccountView.swift
//  Nippardation
//
//  Account / settings: who is signed in, and sign out. Reached from the ··· menu on Plan.
//  A Void list panel on the hull, with the app version pinned at the bottom.
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
        ScrollView {
            VStack(spacing: 0) {
                VoidSectionRow(title: "Signed in as")
                    .padding(.top, VoidSpace.s5)

                VoidListPanel {
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
                    .frame(minHeight: VoidSize.listRow)
                    .accessibilityElement(children: .combine)
                }
                .padding(.top, VoidSpace.s2)

                VoidDestructiveButton(title: "Sign out") {
                    signOut()
                }
                .padding(.horizontal, VoidSpace.insetCard)
                .padding(.top, VoidSpace.s6)
            }
            .padding(.bottom, VoidSpace.s6)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Text(versionString)
                .voidEyebrowSm(VoidColor.text3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, VoidSpace.s3)
                .background(VoidColor.hull)
        }
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

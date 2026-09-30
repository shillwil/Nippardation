//
//  AuthenticationView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 7/18/25.
//
//  Sign-in screen on the hull: mark, RECESS eyebrow, the one display word, squared fields,
//  one plasma CTA. Firebase auth calls and the reset-password alert are unchanged.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var showResetConfirmation = false
    @State private var showAccountCreated = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Mark + name
                Image("WeightIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: VoidRadius.tileHero, style: .continuous))
                    .accessibilityHidden(true)
                    .padding(.top, VoidSpace.topContent)
                
                Text("Recess")
                    .voidEyebrow()
                    .padding(.top, VoidSpace.s5)
                
                Text("Fitness")
                    .voidDisplay(VoidFont.wordRow, size: 30)
                    .padding(.top, 6)
                    .accessibilityLabel("Recess Fitness")
                
                // Form
                VStack(spacing: VoidSpace.s3) {
                    VoidTextField(placeholder: "Email", text: $email, keyboard: .emailAddress, autocapitalization: .never)
                        .textContentType(.emailAddress)
                    
                    VoidSecureField(placeholder: "Password", text: $password, contentType: isSignUp ? .newPassword : .password)
                    
                    if isSignUp {
                        VoidSecureField(placeholder: "Confirm password", text: $confirmPassword, contentType: .newPassword)
                    }
                    
                    if !isSignUp {
                        HStack {
                            Spacer()
                            linkButton("Forgot password?") {
                                resetEmail = email
                                showForgotPassword = true
                            }
                        }
                    }
                }
                .padding(.top, VoidSpace.s6 + VoidSpace.s2)
                
                // Error message
                if let errorMessage = authManager.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(VoidFont.caption)
                        .foregroundStyle(VoidColor.warning)
                        .multilineTextAlignment(.center)
                        .padding(.top, VoidSpace.s4)
                }
                
                // Action
                VoidCTAButton(
                    title: isSignUp ? "Create account" : "Sign in",
                    isEnabled: !authManager.isLoading,
                    isLoading: authManager.isLoading,
                    action: handleAuthAction
                )
                .padding(.top, VoidSpace.s5)
                
                // Toggle between sign in and create account
                linkButton(isSignUp ? "Already have an account? Sign in" : "No account? Create one") {
                    isSignUp.toggle()
                    clearForm()
                }
                .padding(.top, VoidSpace.s3)
            }
            .padding(.horizontal, VoidSpace.insetCard)
            .padding(.bottom, VoidSpace.s6)
        }
        .onAppear {
            // Don't greet a fresh sign-in screen with the last session's error.
            authManager.errorMessage = nil
        }
        .scrollDismissesKeyboard(.interactively)
        .background(VoidColor.hull.ignoresSafeArea())
        .tint(VoidColor.plasmaInk)
        .alert("Reset password", isPresented: $showForgotPassword) {
            TextField("Email", text: $resetEmail)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            Button("Send reset link") {
                Task {
                    do {
                        try await authManager.sendPasswordReset(email: resetEmail)
                        showResetConfirmation = true
                    } catch {
                        // errorMessage is already set by AuthManager
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
        .alert("Email sent", isPresented: $showResetConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Check your email for a password reset link.")
        }
        .alert("Account created", isPresented: $showAccountCreated) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You're signed in and ready to go — no need to log in again.")
        }
    }
    
    // MARK: - Pieces
    
    /// A system text link (borderless, footnote, tinted plasma by the screen) with a 44pt hit target.
    private func linkButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(minHeight: VoidSize.hitMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .font(.footnote)
    }
    
    /// Autofill and paste both like to leave a trailing space; Firebase rejects it as an
    /// invalid email, which reads to the user as "my email doesn't work".
    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Why the form can't be submitted yet, or nil when it can. Shown on tap rather than
    /// leaving an inert button with no explanation.
    private var validationMessage: String? {
        if trimmedEmail.isEmpty { return "Enter your email address." }
        if password.isEmpty { return "Enter your password." }
        guard isSignUp else { return nil }
        if password.count < 6 { return "Your password needs to be at least 6 characters." }
        if confirmPassword.isEmpty { return "Confirm your password." }
        if password != confirmPassword { return "Those passwords don't match." }
        return nil
    }

    private func handleAuthAction() {
        if let validationMessage {
            authManager.errorMessage = validationMessage
            return
        }
        authManager.errorMessage = nil

        Task {
            if isSignUp {
                await signUp()
            } else {
                await signIn()
            }
        }
    }

    /// Creating the account signs the user in as part of the same tap — they never retype
    /// the credentials they just chose. The alert confirms the account exists.
    ///
    /// The one failure worth handling rather than just reporting is an address that already
    /// has an account: on its own that is a loop, where the only button on screen keeps
    /// refusing an address that would sign in fine. So we move them to the other half of the
    /// screen, keep the email they typed, and let the message explain why the form changed.
    private func signUp() async {
        do {
            try await authManager.signUp(email: trimmedEmail, password: password)
            showAccountCreated = true
        } catch {
            if AuthManager.isEmailAlreadyInUse(error) {
                isSignUp = false
                password = ""
                confirmPassword = ""
            }
        }
    }

    private func signIn() async {
        do {
            try await authManager.signIn(email: trimmedEmail, password: password)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        authManager.errorMessage = ""
    }
}

// MARK: - Secure field (Void chrome; the foundation only ships `VoidTextField`)

/// Squared secure field well: panel-2 fill, radius 12, Chakra Petch 15.5 — the `SecureField` twin of `VoidTextField`.
private struct VoidSecureField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    
    var body: some View {
        HStack(spacing: 10) {
            SecureField(placeholder, text: $text)
                .font(VoidFont.body)
                .foregroundStyle(VoidColor.text)
                .textContentType(contentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        // A minimum, not a fixed height: Chakra Petch grows with Dynamic Type.
        .frame(minHeight: VoidSize.pill)
        .voidPanel(radius: VoidRadius.tile, line: VoidColor.hairline2, fill: VoidColor.panel2)
    }
}

#Preview {
    AuthenticationView()
}

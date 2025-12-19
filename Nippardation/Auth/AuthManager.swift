//
//  AuthManager.swift
//  Nippardation
//
//  Created by Claude on 7/10/25.
//

import Foundation
import FirebaseAuth
import Combine

// MARK: - Backend User Model

struct BackendUser: Codable {
    let id: String
    let firebaseUid: String
    let email: String
    let handle: String
    let displayName: String?
    let profilePictureUrl: String?
    let bio: String?
    let unitPreference: String?
    let totalWorkouts: Int?
    let currentWorkoutStreak: Int?
    let createdAt: String?
    let updatedAt: String?
}

struct LoginResponse: Codable {
    let success: Bool
    let message: String
    let user: BackendUser
}

// MARK: - AuthManager

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var user: User?
    @Published var backendUser: BackendUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
            
            if let user = user {
                print("User authenticated: \(user.uid)")
                // Here you would typically sync with your backend
                self?.syncWithBackend(firebaseUser: user)
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("Successfully signed in user: \(result.user.uid)")
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("Successfully created user: \(result.user.uid)")
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            print("Successfully signed out")
        } catch {
            Task { @MainActor in
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Backend Integration
    
    private func syncWithBackend(firebaseUser: User) {
        Task {
            do {
                let idToken = try await firebaseUser.getIDToken()
                await loginToBackend(idToken: idToken)
            } catch {
                NSLog("Error getting ID token: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to sync with backend: \(error.localizedDescription)"
                }
            }
        }
    }

    private func loginToBackend(idToken: String) async {
        do {
            let url = AppConfiguration.shared.baseURL.appendingPathComponent("/api/auth/login")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Invalid response", code: 0)
            }

            guard httpResponse.statusCode == 200 else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Backend login failed: \(errorText)")
                throw NSError(domain: "Backend login failed", code: httpResponse.statusCode)
            }

            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)

            await MainActor.run {
                self.backendUser = loginResponse.user
            }
        } catch {
            NSLog("Error syncing with backend: \(error)")
            await MainActor.run {
                errorMessage = "Failed to sync with backend: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Token Management
    
    func getIDToken() async throws -> String? {
        guard let user = Auth.auth().currentUser else { return nil }
        return try await user.getIDToken()
    }
    
    func refreshToken() async throws {
        guard let user = Auth.auth().currentUser else { return }
        _ = try await user.getIDTokenResult(forcingRefresh: true)
    }
}

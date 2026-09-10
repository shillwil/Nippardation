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
    let height: Double?
    let weight: Double?
    let age: Int?
    let gender: String?
    let unitPreference: String?
    let isPublicProfile: Bool?
    let totalVolumeLiftedLbs: String?
    let totalWorkouts: Int?
    let currentWorkoutStreak: Int?
    let longestWorkoutStreak: Int?
    let lastWorkoutDate: String?
    let pushNotificationTokens: [String]?
    let notificationsEnabled: Bool?
    let lastSyncedAt: String?
    let createdAt: String?
    let updatedAt: String?

}

struct LoginResponse: Codable {
    let success: Bool
    let message: String
    let data: LoginData
}

/// Login data wrapper — server nests user inside data.user
struct LoginData: Codable {
    let user: BackendUser
    let token: String?
}

/// The `{ success, message }` envelope the backend sends on every failure.
private struct BackendErrorEnvelope: Decodable {
    let message: String?
    let error: String?
    let correlationId: String?
}

/// What `signUp` did, so the caller can confirm it in the UI.
enum SignUpOutcome: Equatable {
    /// The account was created and the session is live — nothing more to type.
    case createdAndSignedIn
    /// The account was created but the session had to be re-established; that
    /// second sign-in also succeeded, still without asking for the password again.
    case createdAndSignedInAfterRetry
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
    /// The backend sync in flight, keyed by uid. The listener fires on every launch and on
    /// every auth change, and `/api/auth/login` is rate limited — so never run two at once,
    /// and never repeat a sync for a user already synced.
    private var backendSyncTask: Task<Void, Never>?
    private var syncedUid: String?
    
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
                self?.syncWithBackend(firebaseUser: user)
            } else {
                self?.backendSyncTask?.cancel()
                self?.backendSyncTask = nil
                self?.syncedUid = nil
                self?.backendUser = nil
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
    
    /// Creates the account and leaves the user signed in.
    ///
    /// `createUser` already establishes a session, so the normal path needs no second call.
    /// Signing up and then being asked to type the same email and password again is a
    /// terrible first impression, so if the session is somehow not live afterwards we sign
    /// in with the credentials we were just handed rather than sending the user back to the
    /// form. The returned outcome is what the screen confirms; it never means "now log in".
    @discardableResult
    func signUp(email: String, password: String) async throws -> SignUpOutcome {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("Successfully created user: \(result.user.uid)")

            var outcome = SignUpOutcome.createdAndSignedIn
            if Auth.auth().currentUser == nil {
                // The account exists — finish the job with the credentials we already have.
                _ = try await Auth.auth().signIn(withEmail: email, password: password)
                outcome = .createdAndSignedInAfterRetry
            }

            await MainActor.run {
                isLoading = false
            }
            return outcome
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func sendPasswordReset(email: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
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
            Task { @MainActor in
                // Otherwise the next sign-in screen greets the user with the last session's
                // error, and AccountView shows the previous account's name.
                errorMessage = nil
                backendUser = nil
                syncedUid = nil
            }
        } catch {
            Task { @MainActor in
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Backend Integration
    
    private func syncWithBackend(firebaseUser: User) {
        // Already synced this user, or a sync is in flight: `/api/auth/login` is rate limited,
        // so don't spend a request re-establishing something we already have.
        if syncedUid == firebaseUser.uid, backendUser != nil { return }
        if backendSyncTask != nil { return }

        backendSyncTask = Task { [weak self] in
            defer { Task { @MainActor [weak self] in self?.backendSyncTask = nil } }
            do {
                let idToken = try await firebaseUser.getIDToken()
                if Task.isCancelled { return }
                await self?.loginToBackend(idToken: idToken, uid: firebaseUser.uid)
            } catch {
                NSLog("Error getting ID token: \(error)")
                await MainActor.run { [weak self] in
                    self?.errorMessage = "Couldn't finish signing in: \(error.localizedDescription)"
                }
            }
        }
    }

    private func loginToBackend(idToken: String, uid: String) async {
        do {
            let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/auth/login")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Invalid response", code: 0)
            }

            // Any 2xx is a success. The route returns 200 today, but a 201 on the call that
            // creates the user row is exactly the kind of change that should not sign people out.
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = Self.backendMessage(from: data, statusCode: httpResponse.statusCode)
                print("Backend login failed (\(httpResponse.statusCode)): \(message)")
                throw NSError(
                    domain: "RecessBackend",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            }

            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)

            await MainActor.run {
                self.backendUser = loginResponse.data.user
                self.syncedUid = uid
                self.errorMessage = nil
            }
        } catch {
            NSLog("Error syncing with backend: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// A message worth showing: the backend's own wording where it sends one, and a plain
    /// sentence for the status codes that used to surface as "error 429."
    static func backendMessage(from data: Data, statusCode: Int) -> String {
        if let envelope = try? JSONDecoder().decode(BackendErrorEnvelope.self, from: data),
           let message = envelope.message ?? envelope.error,
           !message.isEmpty {
            return message
        }
        switch statusCode {
        case 401, 403:
            return "Your session couldn't be verified. Try signing in again."
        case 429:
            return "Too many sign-in attempts right now. Wait a minute and try again."
        case 500...599:
            return "The server is having trouble. Try again in a moment."
        default:
            return "Couldn't reach your account (error \(statusCode))."
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

//
//  NippardationApp.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI
import FirebaseCore

@main
struct NippardationApp: App {
    private let coreDataManager = CoreDataManager.shared
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var authManager = AuthManager.shared
    
    init() {
        StringArrayTransformer.register()
        configureFirebase()
    }
    
    private func configureFirebase() {
        // Load the appropriate GoogleService-Info.plist based on environment
        let plistName = AppConfiguration.shared.firebasePlistName
        guard let plistPath = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: plistPath) else {
            print("Error: Could not load Firebase configuration file: \(plistName).plist")
            return
        }
        
        FirebaseApp.configure(options: options)
        print("Firebase configured with \(AppConfiguration.shared.environment.rawValue) environment")
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                HomeView()
                    .environmentObject(authManager)
                    .onChange(of: UIApplication.shared.applicationState) { oldState, newState in
                        if newState == .background {
                            coreDataManager.saveContext()
                            
                            // Force save active workout when going to background
                            if workoutManager.isWorkoutInProgress {
                                WorkoutCacheManager.shared.saveWorkoutCache()
                            }
                        }
                    }
                    // Save context on app termination
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                        coreDataManager.saveContext()
                        
                        // Force save active workout when app is terminating
                        if workoutManager.isWorkoutInProgress {
                            WorkoutCacheManager.shared.saveWorkoutCache()
                        }
                    }
            } else {
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
        
        
    }
}

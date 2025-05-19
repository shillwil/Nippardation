//
//  NippardationApp.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI

import SwiftUI

@main
struct NippardationApp: App {
    private let coreDataManager = CoreDataManager.shared
    @StateObject private var workoutManager = WorkoutManager.shared
    
    init() {
        StringArrayTransformer.register()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                // Save context when app is terminated or goes to background
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
        }
    }
}

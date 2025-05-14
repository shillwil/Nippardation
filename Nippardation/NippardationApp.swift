//
//  NippardationApp.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

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
                .onChange(of: UIApplication.shared.applicationState) { oldState, newState in
                    if newState == .background {
                        coreDataManager.saveContext()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    coreDataManager.saveContext()
                }
        }
    }
}

//
//  NippardationApp.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI
import UIKit
import AVFoundation
import FirebaseCore

@main
struct NippardationApp: App {
    private let coreDataManager = CoreDataManager.shared
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var deepLinkRouter = DeepLinkRouter.shared

    init() {
        // Before anything can create an AVPlayer: exercise demos must mix with the person's music.
        AppAudioSession.configure()
        StringArrayTransformer.register()
        configureFirebase()
        Self.configureNavigationBarTypography()

        // Configure dependency container with real implementations
        DependencyContainer.shared.configureForProduction()

        #if DEBUG
        // `--void-preview` launch argument: mock data, no sign-in (screenshots / design review)
        VoidPreviewMode.configure()
        #endif
    }

    private var showsMainInterface: Bool {
        #if DEBUG
        if VoidPreviewMode.isEnabled { return true }
        #endif
        return authManager.isAuthenticated
    }
    
    /// Puts navigation titles on Chakra Petch (the approved custom-font exception).
    ///
    /// `navigationTitle` has no SwiftUI font modifier, so the title is the one piece of
    /// reading type that only UIKit can reach. Only the title text attributes are set: the
    /// bar's background and material stay the system's (Liquid Glass and the scroll-edge
    /// effect on iOS 26), which replacement bar appearances would override. Bar button items
    /// are deliberately left alone: they are buttons, and buttons keep SF.
    @MainActor
    private static func configureNavigationBarTypography() {
        let titleFont = UIFont(name: VoidFont.labelFontName, size: VoidFont.navTitleSize)
            ?? .systemFont(ofSize: VoidFont.navTitleSize, weight: .semibold)
        let largeTitleFont = UIFont(name: VoidFont.labelFontName, size: VoidFont.navLargeTitleSize)
            ?? .systemFont(ofSize: VoidFont.navLargeTitleSize, weight: .bold)

        let bar = UINavigationBar.appearance()
        bar.titleTextAttributes = [.font: titleFont]
        // Large titles grow with the text size, as the system's own do (34pt at the default).
        bar.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: largeTitleFont)]
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
            if showsMainInterface {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(deepLinkRouter)
                    .onOpenURL { url in
                        deepLinkRouter.handleURL(url)
                    }
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
                    // A media-services reset puts the session back on Solo Ambient; restore Ambient.
                    .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereResetNotification)) { _ in
                        AppAudioSession.configure()
                    }
            } else {
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
        
        
    }
}

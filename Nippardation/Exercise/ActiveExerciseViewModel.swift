//
//  ActiveExerciseViewModel.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/16/25.
//

import SwiftUI
import WebKit
import Combine

class ActiveExerciseViewModel: ObservableObject {
    // Data
    @Published var workout: TrackedWorkout
    @Published var matchingExercise: Exercise?
    @Published var webView: WKWebView?
    
    // Stats
    @Published var totalVolume: Double = 0
    @Published var totalReps: Int = 0
    
    // Exercise details
    let exerciseIndex: Int
    
    // Dependencies
    private let workoutManager = WorkoutManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(workout: TrackedWorkout, exerciseIndex: Int) {
        self.workout = workout
        self.exerciseIndex = exerciseIndex
        
        // Find matching exercise template
        findMatchingExercise()
        
        // Setup WebView if we have a matching exercise
        if let exercise = matchingExercise {
            setupWebView(with: exercise.example)
        }
        
        // Calculate initial stats
        updateStats()
    }
    
    func updateWorkout(_ newWorkout: TrackedWorkout) {
        self.workout = newWorkout
        updateStats()
    }
    
    // Find the matching exercise from the workout templates
    private func findMatchingExercise() {
        let exerciseName = workout.trackedExercises[exerciseIndex].exerciseName
        let allWorkouts = [upperStrength, lowerStrength, pullDay, pushDay, legDay]
        
        for template in allWorkouts {
            if let match = template.exercises.first(where: { $0.type.name == exerciseName }) {
                self.matchingExercise = match
                break
            }
        }
    }
    
    // Setup and configure WebView
    private func setupWebView(with embedString: String) {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        
        loadEmbeddedContent(embedString: embedString, webView: webView)
        self.webView = webView
    }
    
    // Load embedded content into WebView
    private func loadEmbeddedContent(embedString: String, webView: WKWebView) {
        // Check if this is just a YouTube ID
        if embedString.range(of: "<iframe") == nil && embedString.range(of: "http") == nil {
            // Treat as a YouTube video ID
            let videoID = embedString.trimmingCharacters(in: .whitespacesAndNewlines)
            let htmlString = createYouTubeEmbedHTML(videoID: videoID)
            webView.loadHTMLString(htmlString, baseURL: nil)
        }
        // Check if this is a full URL
        else if embedString.starts(with: "http") {
            if let videoID = extractYouTubeID(from: embedString) {
                // It's a YouTube URL
                let htmlString = createYouTubeEmbedHTML(videoID: videoID)
                webView.loadHTMLString(htmlString, baseURL: nil)
            } else {
                // Try to load as a generic URL
                if let url = URL(string: embedString) {
                    webView.load(URLRequest(url: url))
                }
            }
        }
        // Handle full embed code (iframe)
        else {
            let htmlString = """
                <html>
                <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body { margin: 0; padding: 0; }
                        .video-container { position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; }
                        .video-container iframe, .video-container object, .video-container embed {
                            position: absolute; top: 0; left: 0; width: 100%; height: 100%;
                        }
                    </style>
                </head>
                <body>
                    <div class="video-container">
                        \(embedString)
                    </div>
                </body>
                </html>
                """
            webView.loadHTMLString(htmlString, baseURL: nil)
        }
    }
    
    // Create standard YouTube embed HTML
    private func createYouTubeEmbedHTML(videoID: String) -> String {
        return """
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body { margin: 0; padding: 0; }
                    .video-container { position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; }
                    .video-container iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
                </style>
            </head>
            <body>
                <div class="video-container">
                    <iframe src="https://www.youtube.com/embed/\(videoID)?playsinline=1" frameborder="0" allowfullscreen></iframe>
                </div>
            </body>
            </html>
            """
    }
    
    // Extract YouTube video ID from URL
    private func extractYouTubeID(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        // Handle youtube.com/watch?v= format
        if url.host?.contains("youtube.com") == true,
           let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let videoID = queryItems.first(where: { $0.name == "v" })?.value {
            return videoID
        }
        
        // Handle youtu.be/videoID format
        if url.host == "youtu.be" {
            return url.lastPathComponent
        }
        
        return nil
    }
    
    // MARK: - Set Management
    
    // Add a set to the current exercise
    func addSet(_ set: TrackedSet) {
        workout.trackedExercises[exerciseIndex].trackedSets.append(set)
        
        // Update in WorkoutManager
        workoutManager.updateTrackedSet(exerciseIndex: exerciseIndex, set: set)
        
        // Recalculate stats
        updateStats()
    }
    
    // Update a set at the specified index
    func updateSet(at index: Int, reps: Int, weight: Double, setType: SetType) {
        guard index < workout.trackedExercises[exerciseIndex].trackedSets.count else { return }
        
        var updatedSet = workout.trackedExercises[exerciseIndex].trackedSets[index]
        updatedSet.reps = reps
        updatedSet.weight = weight
        updatedSet.setType = setType
        workout.trackedExercises[exerciseIndex].trackedSets[index] = updatedSet
        
        // Update in WorkoutManager
        workoutManager.updateSet(exerciseIndex: exerciseIndex, setIndex: index, reps: reps, weight: weight, setType: setType)
        
        // Recalculate stats
        updateStats()
    }
    
    // Delete a set at the specified index
    func deleteSet(at index: Int) {
        guard index < workout.trackedExercises[exerciseIndex].trackedSets.count else { return }
        
        workout.trackedExercises[exerciseIndex].trackedSets.remove(at: index)
        
        // Update in WorkoutManager
        workoutManager.removeTrackedSet(exerciseIndex: exerciseIndex, setIndex: index)
        
        // Recalculate stats
        updateStats()
    }
    
    // MARK: - Stats
    
    // Update workout statistics
    private func updateStats() {
        let sets = workout.trackedExercises[exerciseIndex].trackedSets
        
        // Calculate total volume
        totalVolume = sets.reduce(0.0) { sum, set in
            sum + (Double(set.reps) * set.weight)
        }
        
        // Calculate total reps
        totalReps = sets.reduce(0) { $0 + $1.reps }
    }
    
    // Get current tracked exercise
    var currentExercise: TrackedExercise {
        return workout.trackedExercises[exerciseIndex]
    }
}

//
//  ActiveExerciseDetailView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/14/25.
//

import SwiftUI
import WebKit

struct ActiveExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var workoutManager = WorkoutManager.shared
    @Binding var workout: TrackedWorkout
    let exerciseIndex: Int
    
    @State private var isShowingAddSet = false
    @State private var isEditingSet = false
    @State private var selectedSetIndex: Int?
    @State private var editingReps: Int = 0
    @State private var editingWeight: Double = 0.0
    @State private var webView: WKWebView?
    @State private var exercise: Exercise?
    
    init(workout: Binding<TrackedWorkout>, exerciseIndex: Int) {
        self._workout = workout
        self.exerciseIndex = exerciseIndex
        
        // Find the matching exercise from the templates
        let exerciseName = workout.wrappedValue.trackedExercises[exerciseIndex].exerciseName
        let allWorkouts = [upperStrength, lowerStrength, pullDay, pushDay, legDay]
        
        for template in allWorkouts {
            if let matchingExercise = template.exercises.first(where: { $0.type.name == exerciseName }) {
                self._exercise = State(initialValue: matchingExercise)
                
                // Configure WebView
                let config = WKWebViewConfiguration()
                config.allowsInlineMediaPlayback = true
                config.mediaTypesRequiringUserActionForPlayback = []
                self._webView = State(initialValue: WKWebView(frame: .zero, configuration: config))
                
                if let webView = self._webView.wrappedValue {
                    loadEmbeddedContent(embedString: matchingExercise.example, webView: webView)
                }
                
                break
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Exercise Information
                    if let exercise = exercise {
                        Group {
                            // Target information
                            VStack(alignment: .leading, spacing: 12) {
                                targetInfoRow(title: "Target Sets", value: "\(exercise.warmUpSets) warm-up + \(exercise.workingSets) working")
                                targetInfoRow(title: "Target Reps", value: "\(exercise.reps.lowerBound)-\(exercise.reps.upperBound)")
                                targetInfoRow(title: "Rest Period", value: "\(exercise.rest.lowerBound)-\(exercise.rest.upperBound) min")
                                targetInfoRow(title: "Intensity Technique", value: exercise.lastSetIntensityTechnique)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Example video
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Example")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if let webView = webView {
                                    WebViewRepresentable(webView: webView)
                                        .aspectRatio(1.8, contentMode: .fit)
                                        .cornerRadius(12)
                                        .frame(height: 200)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Tracked Sets Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Tracked Sets")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button {
                                    isShowingAddSet = true
                                } label: {
                                    Label("Add Set", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)
                            
                            // Add a debug Text element to check if sets are tracked
                            Text("Sets count: \(workout.trackedExercises[exerciseIndex].trackedSets.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            if workout.trackedExercises[exerciseIndex].trackedSets.isEmpty {
                                Text("No sets tracked yet")
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(Array(zip(workout.trackedExercises[exerciseIndex].trackedSets.indices, workout.trackedExercises[exerciseIndex].trackedSets)), id: \.0) { index, set in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(set.setType == .warmup ? "Warm-up Set" : "Working Set")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                
                                                Text("Set \(index + 1)")
                                                    .font(.headline)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("\(set.reps) reps")
                                                    .font(.headline)
                                                
                                                Text("\(Int(set.weight)) lbs")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            // Edit and Delete buttons
                                            Menu {
                                                Button {
                                                    selectedSetIndex = index
                                                    editingReps = set.reps
                                                    editingWeight = set.weight
                                                    isEditingSet = true
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                
                                                Button(role: .destructive) {
                                                    deleteSet(at: index)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            } label: {
                                                Image(systemName: "ellipsis.circle")
                                                    .font(.title3)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Volume Summary
                            let totalVolume = workout.trackedExercises[exerciseIndex].trackedSets.reduce(0.0) { sum, set in
                                sum + (Double(set.reps) * set.weight)
                            }
                            
                            if totalVolume > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Summary")
                                        .font(.headline)
                                    
                                    HStack {
                                        Spacer()
                                        
                                        volumeStatView(
                                            title: "Sets",
                                            value: "\(workout.trackedExercises[exerciseIndex].trackedSets.count)",
                                            icon: "number.square.fill"
                                        )
                                        
                                        Spacer()
                                        
                                        let totalReps = workout.trackedExercises[exerciseIndex].trackedSets.reduce(0) { $0 + $1.reps }
                                        volumeStatView(
                                            title: "Reps",
                                            value: "\(totalReps)",
                                            icon: "repeat.circle.fill"
                                        )
                                        
                                        Spacer()
                                        
                                        volumeStatView(
                                            title: "Volume",
                                            value: "\(Int(totalVolume))",
                                            icon: "chart.bar.fill"
                                        )
                                        
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle(workout.trackedExercises[exerciseIndex].exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSet) {
                if let exercise = exercise {
                    AddRepCountView(exercise: exercise) { newSet in
                        addSet(newSet)
                    }
                    .presentationDetents([.fraction(0.75)])
                }
            }
            .sheet(isPresented: $isEditingSet) {
                if let index = selectedSetIndex,
                   index < workout.trackedExercises[exerciseIndex].trackedSets.count {
                    EditSetView(
                        reps: $editingReps,
                        weight: $editingWeight,
                        onSave: { newReps, newWeight in
                            updateSet(at: index, reps: newReps, weight: newWeight)
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
        }
    }
    
    @ViewBuilder
    private func targetInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    @ViewBuilder
    private func volumeStatView(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
    }
    
    private func addSet(_ set: TrackedSet) {
        var updatedWorkout = workout
        updatedWorkout.trackedExercises[exerciseIndex].trackedSets.append(set)
        workout = updatedWorkout
        
        // Update in WorkoutManager
        workoutManager.updateTrackedSet(exerciseIndex: exerciseIndex, set: set)
    }
    
    private func updateSet(at index: Int, reps: Int, weight: Double) {
        guard index < workout.trackedExercises[exerciseIndex].trackedSets.count else { return }
        
        var updatedWorkout = workout
        var updatedSet = updatedWorkout.trackedExercises[exerciseIndex].trackedSets[index]
        updatedSet.reps = reps
        updatedSet.weight = weight
        updatedWorkout.trackedExercises[exerciseIndex].trackedSets[index] = updatedSet
        workout = updatedWorkout
        
        // Update in WorkoutManager
        workoutManager.updateSet(exerciseIndex: exerciseIndex, setIndex: index, reps: reps, weight: weight)
    }
    
    private func deleteSet(at index: Int) {
        var updatedWorkout = workout
        updatedWorkout.trackedExercises[exerciseIndex].trackedSets.remove(at: index)
        workout = updatedWorkout
        
        // Update in WorkoutManager
        workoutManager.removeTrackedSet(exerciseIndex: exerciseIndex, setIndex: index)
    }
    
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
}

// Edit Set View for modifying existing sets
struct EditSetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var reps: Int
    @Binding var weight: Double
    var onSave: (Int, Double) -> Void
    
    @State private var weightString: String = ""
    @State private var showingWeightPicker = false
    
    init(reps: Binding<Int>, weight: Binding<Double>, onSave: @escaping (Int, Double) -> Void) {
        self._reps = reps
        self._weight = weight
        self.onSave = onSave
        self._weightString = State(initialValue: String(format: "%.1f", weight.wrappedValue))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit Set")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Reps section
                VStack(alignment: .leading, spacing: 8) {
                    Text("REPS")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button {
                            if reps > 1 {
                                reps -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("\(reps)")
                            .font(.system(size: 48, weight: .bold))
                        
                        Spacer()
                        
                        Button {
                            reps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Weight section
                VStack(alignment: .leading, spacing: 8) {
                    Text("WEIGHT (LBS)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingWeightPicker = true
                    } label: {
                        HStack {
                            Text("\(weight, specifier: "%.1f")")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save button
                Button {
                    onSave(reps, weight)
                    dismiss()
                } label: {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    onSave(reps, weight)
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    ActiveExerciseDetailView(
        workout: .constant(TrackedWorkout(
            date: Date(),
            workoutTemplate: "Pull Day (Hypertrophy Focus)",
            trackedExercises: [
                TrackedExercise(
                    exerciseName: "TEst exercise",
                    muscleGroups: [MuscleGroup.shoulders.rawValue],
                    trackedSets: [
                        TrackedSet(reps: 8, weight: 32.5, setType: .warmup, exerciseType: ExerciseType(name: "EZ Bar Curl", muscleGroup: [.biceps]))
                    ]
                )
            ])
        ),
        exerciseIndex: 0)
}

//
//  ExerciseDetailView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI

struct ExerciseDetailView: View {
    @Binding var exercise: Exercise
    @State private var isShowingActionSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                labelText(title: "Warm-up Sets", setNumber: exercise.warmUpSets)
                
                labelText(title: "Working Sets", setNumber: exercise.workingSets)
                
                labelText(title: "Reps", range: exercise.reps)
                
                HStack {
                    labelText(title: "Rest time between sets", range: exercise.rest)
                    Text("min")
                        .font(.title3)
                        .bold()
                }
                
                HStack {
                    Text("Example:")
                        .font(.title)
                        .bold()
                    Spacer()
                }
                .padding(.top)
                
                playVideoButton()
                
                
                
                Spacer()
            }
            .padding()
            .navigationTitle(exercise.type.name)
            .actionSheet(isPresented: $isShowingActionSheet) {
                ActionSheet(
                    title: Text("Watch Video"),
                    message: Text("Choose how to open this video"),
                    buttons: [
                        .default(Text("Open in YouTube App")) {
                            openInYouTube()
                        },
                        .default(Text("Open in Safari")) {
                            openInSafari()
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    @ViewBuilder
    private func labelText(title: String, setNumber: Int? = nil, range: ClosedRange<Int>? = nil) -> some View {
        HStack {
            Text(title)
                
            Spacer()
            if let setNumber {
                Text("\(setNumber)")
            }
            if let range {
                Text("\(range.lowerBound)-\(range.upperBound)")
            }
        }
        .font(.title3)
        .bold()
    }
    
    @ViewBuilder
    private func playVideoButton() -> some View {
        Button(action: {
            self.isShowingActionSheet = true
        }) {
            ZStack {
                Color.blue
                HStack {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                        .padding(.vertical)
                    
                    Text("Tap to watch video")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxHeight: 80)
            .cornerRadius(16)
        }
        .padding()
    }
    
    // Open in YouTube app
    private func openInYouTube() {
        let embedString = exercise.example
        
        var videoID: String? = nil
        
        // Extract video ID depending on format
        if embedString.range(of: "<iframe") == nil && embedString.range(of: "http") == nil {
            // Treat as a direct YouTube ID
            videoID = embedString.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if embedString.starts(with: "http") {
            videoID = extractYouTubeID(from: embedString)
        } else {
            // Try to extract from iframe
            let pattern = "youtube.com/embed/([^\\?\"]+)"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: embedString, range: NSRange(embedString.startIndex..., in: embedString)) {
                let idRange = Range(match.range(at: 1), in: embedString)!
                videoID = String(embedString[idRange])
            }
        }
        
        guard let videoID = videoID else { return }
        
        // Try to open in YouTube app first
        let youtubeAppURL = URL(string: "youtube://\(videoID)")!
        if UIApplication.shared.canOpenURL(youtubeAppURL) {
            UIApplication.shared.open(youtubeAppURL)
        } else {
            // Fallback to website
            let youtubeWebURL = URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
            UIApplication.shared.open(youtubeWebURL)
        }
    }
    
    // Open in Safari
    private func openInSafari() {
        let embedString = exercise.example
        
        var urlToOpen: URL? = nil
        
        // Determine URL to open
        if embedString.range(of: "<iframe") == nil && embedString.range(of: "http") == nil {
            // Treat as a direct YouTube ID
            let videoID = embedString.trimmingCharacters(in: .whitespacesAndNewlines)
            urlToOpen = URL(string: "https://www.youtube.com/watch?v=\(videoID)")
        } else if embedString.starts(with: "http") {
            urlToOpen = URL(string: embedString)
        } else {
            // Try to extract from iframe
            let pattern = "src=\"([^\"]+)\""
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: embedString, range: NSRange(embedString.startIndex..., in: embedString)) {
                if let urlRange = Range(match.range(at: 1), in: embedString) {
                    let urlString = String(embedString[urlRange])
                    urlToOpen = URL(string: urlString)
                }
            }
        }
        
        if let url = urlToOpen {
            UIApplication.shared.open(url)
        }
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
#Preview {
    ExerciseDetailView(exercise: .constant(Exercise(
        type: ExerciseType(name: "Neutral-Grip Lat Pulldown", muscleGroup: [.back, .biceps], dayAssociation: [.wednesday]),
        example: """
                <iframe width="560" height="315" src="https://www.youtube.com/embed/lA4_1F9EAFU?si=cXDvOvhQYxFLdnwu" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                """,
        lastSetIntensityTechnique: "Failure",
        warmUpSets: 2,
        workingSets: 2,
        reps: 8...10,
        rest: 2...3,
        trackedSets: []
    )))
}

//
//  ExerciseDetailView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/8/25.
//

import SwiftUI
import WebKit

struct ExerciseDetailView: View {
    var exercise: Exercise
    @State private var isShowingActionSheet = false
    @ObservedObject private var viewModel = ExerciseViewModel()
    @State var presentRepCounter: Bool = false
    private var webView: WKWebView?
    
    init(exercise: Exercise, isShowingActionSheet: Bool = false, viewModel: ExerciseViewModel = ExerciseViewModel(), presentRepCounter: Bool = false, webView: WKWebView? = nil) {
        self.exercise = exercise
        self.isShowingActionSheet = isShowingActionSheet
        self.viewModel = viewModel
        self.presentRepCounter = presentRepCounter
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        self.webView = WKWebView(frame: .zero, configuration: config)
        
        loadEmbeddedContent(embedString: exercise.example)
    }
    
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
                
                labelText(title: "Last Set Intensity Technique", text: exercise.lastSetIntensityTechnique)
                
                HStack {
                    Text("Example:")
                        .font(.title)
                        .bold()
                    Spacer()
                }
                .padding(.top)
                
                if let webView = webView {
                    WebViewRepresentable(webView: webView)
                        .aspectRatio(1.8, contentMode: .fit)
                        .cornerRadius(16)
                } else {
                    openYouTubeButton()
                }
                
                //                List {
                //                    Section("Tracked Sets") {
                //                        if viewModel.trackedSets.isEmpty {
                //                            Text("No sets tracked yet")
                //                                .foregroundColor(.gray)
                //                                .padding()
                //                        } else {
                //                            ForEach(viewModel.trackedSets) { set in
                //                                HStack {
                //                                    Text("Set \(viewModel.trackedSets.firstIndex(of: set)! + 1)")
                //                                        .font(.headline)
                //                                    Spacer()
                //                                    Text("\(set.reps) reps")
                //                                        .font(.headline)
                //                                }
                //                                .padding(.vertical, 8)
                //                                .cornerRadius(8)
                //                            }
                //                            .onDelete(perform: viewModel.deleteSet)
                //                        }
                //                    }
                //                }
                //                .listStyle(.plain)
                //                .frame(height: 300)
                //                .cornerRadius(16)
                //
                //                HStack {
                //                    Spacer()
                //
                //                    Button {
                //                        presentRepCounter = true
                //                    } label: {
                //                        Text("Add Set")
                //                            .foregroundStyle(.white)
                //                            .frame(width: 150, height: 50)
                //                            .background(Color.blue)
                //                            .cornerRadius(16)
                //                    }
                //                    .padding()
                //                }
                
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.large)
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
            .sheet(isPresented: $presentRepCounter) {
                AddRepCountView(exercise: exercise) { newSet in
                    viewModel.addSet(newSet)
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    @ViewBuilder
    private func labelText(title: String, setNumber: Int? = nil, range: ClosedRange<Int>? = nil, text: String? = nil) -> some View {
        HStack {
            Text(title)
            
            Spacer()
            if let setNumber {
                Text("\(setNumber)")
            }
            if let range {
                Text("\(range.lowerBound)-\(range.upperBound)")
            }
            if let text {
                Text("\(text)")
            }
        }
        .font(.title3)
        .bold()
    }
    
    @ViewBuilder
    private func openYouTubeButton() -> some View {
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
    
    private func loadEmbeddedContent(embedString: String) {
        // Check if this is just a YouTube ID
        if embedString.range(of: "<iframe") == nil && embedString.range(of: "http") == nil {
            // Treat as a YouTube video ID
            let videoID = embedString.trimmingCharacters(in: .whitespacesAndNewlines)
            let htmlString = createYouTubeEmbedHTML(videoID: videoID)
            webView?.loadHTMLString(htmlString, baseURL: nil)
        }
        // Check if this is a full URL
        else if embedString.starts(with: "http") {
            if let videoID = extractYouTubeID(from: embedString) {
                // It's a YouTube URL
                let htmlString = createYouTubeEmbedHTML(videoID: videoID)
                webView?.loadHTMLString(htmlString, baseURL: nil)
            } else {
                // Try to load as a generic URL
                if let url = URL(string: embedString) {
                    webView?.load(URLRequest(url: url))
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
            webView?.loadHTMLString(htmlString, baseURL: nil)
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
                    <iframe src="https://www.youtube.com/embed/\(videoID)?playsinline=1&autoplay=1" frameborder="0" allowfullscreen></iframe>
                </div>
            </body>
            </html>
            """
    }
}

// SwiftUI wrapper for WKWebView
struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Updates handled in the main view
    }
}

#Preview {
    ExerciseDetailView(exercise: Exercise(
        type: ExerciseType(name: "Neutral-Grip Lat Pulldown", muscleGroup: [.back, .biceps]),
        example: """
                <iframe width="560" height="315" src="https://www.youtube.com/embed/lA4_1F9EAFU?si=cXDvOvhQYxFLdnwu" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
                """,
        lastSetIntensityTechnique: "Failure",
        warmUpSets: 2,
        workingSets: 2,
        reps: 8...10,
        rest: 2...3,
    ))
}

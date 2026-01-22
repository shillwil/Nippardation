//
//  VideoPlayerViewModel.swift
//  Nippardation
//
//  ViewModel for native video player using AVPlayer
//

import Foundation
import AVFoundation
import Combine

/// ViewModel for native video player
@MainActor
final class VideoPlayerViewModel: ObservableObject {

    // MARK: - Published State

    @Published var isLoading = false
    @Published var isPlaying = false
    @Published var isMuted = true // Start muted by default for exercise demos
    @Published var error: String?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLooping = true
    @Published var downloadProgress: Double = 0

    // MARK: - Player

    let player: AVPlayer
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var playerItemCancellables = Set<AnyCancellable>() // Separate set for player item subscriptions

    // MARK: - Dependencies

    private let videoCacheService: any VideoCacheServiceProtocol

    // MARK: - State

    private var currentExerciseServerId: String?
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init(videoCacheService: (any VideoCacheServiceProtocol)? = nil) {
        self.videoCacheService = videoCacheService ?? DependencyContainer.shared.videoCacheService
        self.player = AVPlayer()

        setupPlayer()
        observeDownloadProgress()
    }

    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        loadTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load a video for an exercise
    /// - Parameters:
    ///   - exerciseServerId: The server ID of the exercise
    ///   - videoUrl: The remote URL of the video (optional if already cached)
    func loadVideo(exerciseServerId: String, videoUrl: URL?) async {
        // Don't reload same video if already loaded successfully
        if currentExerciseServerId == exerciseServerId && playerItem != nil && error == nil {
            return
        }

        // Cancel any previous load
        loadTask?.cancel()
        loadTask = nil

        // Reset state for new video
        currentExerciseServerId = exerciseServerId
        isLoading = true
        error = nil
        downloadProgress = 0
        currentTime = 0
        duration = 0

        // Check if already cached
        if let localURL = videoCacheService.getCachedVideoURL(for: exerciseServerId) {
            setupPlayerItem(with: localURL)
            isLoading = false
            await videoCacheService.touchVideo(for: exerciseServerId)
            return
        }

        // Need to download - requires video URL
        guard let remoteURL = videoUrl else {
            error = "No video URL available"
            isLoading = false
            return
        }

        loadTask = Task {
            do {
                let localURL = try await videoCacheService.cacheVideo(
                    for: exerciseServerId,
                    from: remoteURL
                )

                if !Task.isCancelled {
                    setupPlayerItem(with: localURL)
                    isLoading = false
                }
            } catch {
                if !Task.isCancelled {
                    self.error = "Failed to load video"
                    self.isLoading = false
                }
            }
        }
    }

    /// Load video directly from a URL (for preview/testing)
    func loadVideo(from url: URL) {
        setupPlayerItem(with: url)
    }

    /// Play the video
    func play() {
        player.play()
        isPlaying = true
    }

    /// Pause the video
    func pause() {
        player.pause()
        isPlaying = false
    }

    /// Toggle play/pause state
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// Toggle mute state
    func toggleMute() {
        isMuted.toggle()
        player.isMuted = isMuted
    }

    /// Seek to a specific time
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
    }

    /// Restart the video from the beginning
    func restart() {
        seek(to: 0)
        play()
    }

    /// Stop and clean up the player
    func stop() {
        loadTask?.cancel()
        loadTask = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        playerItem = nil
        playerItemCancellables.removeAll() // Clean up player item subscriptions
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        currentExerciseServerId = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        error = nil
    }

    // MARK: - Private Methods

    private func setupPlayer() {
        player.isMuted = isMuted

        // Observe playback state
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isPlaying = status == .playing
            }
            .store(in: &cancellables)
    }

    private func observeDownloadProgress() {
        videoCacheService.downloadProgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self,
                      progress.exerciseServerId == self.currentExerciseServerId else {
                    return
                }
                self.downloadProgress = progress.fractionComplete
            }
            .store(in: &cancellables)
    }

    private func setupPlayerItem(with url: URL) {
        // Clean up previous item's subscriptions to prevent memory leaks
        playerItemCancellables.removeAll()

        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }

        // Create new player item
        let item = AVPlayerItem(url: url)
        playerItem = item
        player.replaceCurrentItem(with: item)

        // Observe duration - stored in player item specific set
        item.publisher(for: \.duration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                if duration.isNumeric {
                    self?.duration = duration.seconds
                }
            }
            .store(in: &playerItemCancellables)

        // Observe status for errors
        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .failed {
                    self?.error = "Failed to play video"
                }
            }
            .store(in: &playerItemCancellables)

        // Add time observer
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            self?.currentTime = time.seconds
        }

        // Observe end of playback for looping
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.isLooping == true {
                    self?.restart()
                }
            }
            .store(in: &playerItemCancellables)

        // Auto-play
        play()
    }
}

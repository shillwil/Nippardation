//
//  VideoPlayerViewModel.swift
//  Nippardation
//
//  Loads an exercise demo through the video cache and drives one muted, looping AVPlayer.
//  NativeVideoPlayer shows it with AVKit's `VideoPlayer`; ExercisePreviewCard tiles show it
//  on a bare AVPlayerLayer. The system owns the transport controls, so nothing here tracks
//  time or duration for a hand-drawn UI. The player's rate is watched only to tell a pause
//  made with those controls from the view model's own, so a demo someone paused stays paused.
//
//  Demos start by themselves only while Settings › Accessibility › Motion › Auto-Play Video
//  Previews is on. Off, a demo loads to its first frame and waits for the system Play button.
//

import Foundation
import AVFoundation
import Combine
import UIKit

/// ViewModel for the exercise demo players
@MainActor
final class VideoPlayerViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var downloadProgress: Double = 0
    @Published private(set) var detectedAspectRatio: CGFloat = 16/9

    /// Demos loop. With `actionAtItemEnd = .none` the player never pauses at the end,
    /// so the system controls don't flip to Play on every lap.
    var isLooping = true {
        didSet { player.actionAtItemEnd = isLooping ? .none : .pause }
    }

    // MARK: - Player

    let player: AVPlayer
    private var playerItem: AVPlayerItem?
    private var cancellables = Set<AnyCancellable>()
    private var playerItemCancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let videoCacheService: any VideoCacheServiceProtocol
    private let audioSession: any AudioSessionConfigurable
    /// Auto-Play Video Previews (UIAccessibility), read each time the player would start itself.
    private let isAutoplayEnabled: @MainActor () -> Bool

    // MARK: - State

    private var currentExerciseServerId: String?
    private var currentVideoUrl: URL?
    private var loadTask: Task<Void, Never>?
    /// Bumped by every load; work that finishes for an older load is dropped.
    private var loadGeneration = 0
    /// True while the owning view is on screen. A load that finishes after the view has
    /// gone must not start a player nobody can see (it would still decode video and
    /// activate the audio session).
    private(set) var wantsPlayback = false
    /// True from a start (the view model's, or Play in the controls after a pause made there)
    /// until a pause. The view model's own pauses clear it first, so a setRate pause that
    /// lands while it's set came from the controls.
    private var didStartPlayer = false
    /// Paused with the system controls. Coming back on screen (a scroll, a detent change, a
    /// rebuilt row, the app returning) doesn't restart it; Play or the next video clears it.
    private(set) var isPausedByUser = false

    // MARK: - Initialization

    init(
        videoCacheService: (any VideoCacheServiceProtocol)? = nil,
        audioSession: any AudioSessionConfigurable = AVAudioSession.sharedInstance(),
        isAutoplayEnabled: @escaping @MainActor () -> Bool = { UIAccessibility.isVideoAutoplayEnabled }
    ) {
        self.videoCacheService = videoCacheService ?? DependencyContainer.shared.videoCacheService
        self.audioSession = audioSession
        self.isAutoplayEnabled = isAutoplayEnabled
        self.player = AVPlayer()

        // The demos are silent and muted. Muting does not stop the player from activating
        // the app's audio session (the files carry a silent AAC track), so other apps' music
        // keeps playing only because the session category is Ambient (see AppAudioSession).
        player.isMuted = true
        player.actionAtItemEnd = .none

        observeDownloadProgress()
        observePlayerRate()
        observeAutoplaySetting()
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load a video for an exercise and play it while the owning view is on screen.
    /// - Parameters:
    ///   - exerciseServerId: The server ID of the exercise
    ///   - videoUrl: The remote URL of the video (optional if already cached)
    func loadVideo(exerciseServerId: String, videoUrl: URL?) async {
        wantsPlayback = true

        // Same video, loaded or still downloading (a view re-appearing): just resume, unless
        // it was paused with the controls.
        if currentExerciseServerId == exerciseServerId,
           currentVideoUrl == videoUrl,
           error == nil,
           playerItem != nil || loadTask != nil {
            resumeIfWanted()
            return
        }

        // Cancel any previous load
        loadTask?.cancel()
        loadTask = nil
        loadGeneration += 1
        let generation = loadGeneration

        // Reset state for the new video, and stop the previous one so it doesn't keep
        // decoding under the loading cover. The previous aspect ratio stays until the new
        // one is measured, so swapping between two portrait demos doesn't flash to 16:9.
        currentExerciseServerId = exerciseServerId
        currentVideoUrl = videoUrl
        isLoading = true
        error = nil
        downloadProgress = 0
        clearPlayerItem()

        // Check if already cached. Pass the expected remote URL so a stale cache
        // entry (e.g., downloaded before an R2 re-upload changed filenames) is
        // evicted rather than played back from a dead reference.
        if let localURL = videoCacheService.getCachedVideoURL(
            for: exerciseServerId,
            matching: videoUrl
        ) {
            await show(localURL, generation: generation)
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
            let url: URL
            do {
                url = try await videoCacheService.cacheVideo(for: exerciseServerId, from: remoteURL)
            } catch {
                // Cache download failed — fall back to direct streaming
                url = remoteURL
            }
            guard !Task.isCancelled else { return }
            await show(url, generation: generation)
            if generation == loadGeneration {
                loadTask = nil
            }
        }
    }

    /// Play, or resume, while the owning view is on screen.
    func play() {
        wantsPlayback = true
        resumeIfWanted()
    }

    /// Pause, and keep a load that finishes later from starting playback.
    func pause() {
        wantsPlayback = false
        stopPlayer()
    }

    /// Starts the player if the owning view is on screen, a video is in, nobody paused it
    /// with the controls, and Auto-Play Video Previews is on. The views also call this when
    /// the app returns: iOS pauses video players when the app leaves the foreground.
    func resumeIfWanted() {
        guard wantsPlayback,
              playerItem != nil,
              error == nil,
              !isPausedByUser,
              isAutoplayEnabled() else { return }
        startPlayback()
    }

    /// A rate change, with the rate as it was when the change was posted. Changes arrive a
    /// beat late, and AVFoundation can replay a quick stop-and-start as a second pair of
    /// changes, so each one is weighed against the player's rate now.
    /// - A setRate to zero (AVKit's Pause), with the player still stopped, after a start the
    ///   view model hasn't undone, is the person's pause. Interruptions and the app leaving
    ///   the foreground carry other reasons.
    /// - A start, with the player still playing, clears that pause. Right after the person's
    ///   pause it's Play in the controls, which counts as a start. Otherwise it's the view
    ///   model's own start (already counted) or a replay after its own stop (which mustn't).
    func playerRateDidChange(to rate: Float, reason: AVPlayer.RateDidChangeReason?) {
        if rate > 0 {
            guard player.rate > 0 else { return }
            if isPausedByUser {
                didStartPlayer = true
            }
            isPausedByUser = false
        } else if reason == .setRateCalled, didStartPlayer, player.rate == 0 {
            isPausedByUser = true
            didStartPlayer = false
        }
    }

    /// Auto-Play Video Previews changed: turned off, a playing demo stops; turned on, one
    /// that's on screen starts.
    func autoplaySettingDidChange() {
        if isAutoplayEnabled() {
            resumeIfWanted()
        } else {
            stopPlayer()
        }
    }

    // MARK: - Private Methods

    /// Every path that starts the player comes through here, so the session is Ambient
    /// first even if something reset it (a media-services reset, a web view).
    private func startPlayback() {
        AppAudioSession.configure(audioSession)
        didStartPlayer = true
        player.play()
    }

    /// Every pause the view model makes comes through here, so none reads as the person's.
    private func stopPlayer() {
        didStartPlayer = false
        player.pause()
    }

    private func observePlayerRate() {
        let reasonKey = AVPlayer.rateDidChangeReasonKey
        NotificationCenter.default.publisher(for: AVPlayer.rateDidChangeNotification, object: player)
            // Read the rate where the change is posted (often AVFoundation's own queue): by
            // the time the main queue runs the sink, the view model may have changed it again.
            .map { @Sendable note -> (rate: Float, reason: AVPlayer.RateDidChangeReason?) in
                let rate = (note.object as? AVPlayer)?.rate ?? 0
                let reason = note.userInfo?[reasonKey] as? String
                return (rate, reason.map(AVPlayer.RateDidChangeReason.init(rawValue:)))
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                self?.playerRateDidChange(to: change.rate, reason: change.reason)
            }
            .store(in: &cancellables)
    }

    private func observeAutoplaySetting() {
        NotificationCenter.default.publisher(for: UIAccessibility.videoAutoplayStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.autoplaySettingDidChange()
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

    /// Puts `url` in the player and measures it, unless a newer load has started.
    private func show(_ url: URL, generation: Int) async {
        guard generation == loadGeneration else { return }
        setupPlayerItem(with: url)

        let ratio = await aspectRatio(of: url)
        guard generation == loadGeneration else { return }
        if let ratio {
            detectedAspectRatio = ratio
        }
        isLoading = false
    }

    private func aspectRatio(of url: URL) async -> CGFloat? {
        let asset = AVURLAsset(url: url)
        do {
            guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                print("[VideoOrientation] No video tracks found for \(url.lastPathComponent)")
                return nil
            }

            let naturalSize = try await videoTrack.load(.naturalSize)
            let preferredTransform = try await videoTrack.load(.preferredTransform)

            // Apply transform to get actual rendered dimensions.
            // Adobe exports typically have an identity transform, so this is a no-op.
            // Phone-recorded videos may have a 90-degree rotation transform.
            let transformedSize = naturalSize.applying(preferredTransform)
            let width = abs(transformedSize.width)
            let height = abs(transformedSize.height)

            guard width > 0, height > 0 else { return nil }
            return width / height
        } catch {
            print("[VideoOrientation] Detection failed for \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    private func clearPlayerItem() {
        playerItemCancellables.removeAll()
        // Stopped first: the rate outlives the item, so the next one would start by itself.
        stopPlayer()
        player.replaceCurrentItem(with: nil)
        playerItem = nil
        // A new video starts fresh.
        isPausedByUser = false
    }

    private func setupPlayerItem(with url: URL) {
        // Clean up previous item's subscriptions to prevent memory leaks
        playerItemCancellables.removeAll()

        let item = AVPlayerItem(url: url)
        playerItem = item
        player.replaceCurrentItem(with: item)
        // Every demo starts muted, even if the last one was unmuted from the system controls.
        player.isMuted = true

        // Observe status for errors
        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak item] status in
                guard status == .failed else { return }
                let underlying = item?.error
                let detail = underlying?.localizedDescription ?? "unknown error"
                print("[VideoPlayer] Playback failed for \(url.absoluteString) — \(detail)")
                if let nsError = underlying as NSError? {
                    print("[VideoPlayer]   domain=\(nsError.domain) code=\(nsError.code) userInfo=\(nsError.userInfo)")
                }
                self?.error = "The video couldn't be played."
            }
            .store(in: &playerItemCancellables)

        // Loop: the player keeps its rate at the end (actionAtItemEnd = .none), so a seek
        // back to the start carries straight on without a pause/play round trip.
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.isLooping else { return }
                self.player.seek(to: .zero)
            }
            .store(in: &playerItemCancellables)

        // Auto-play, but only for a view that is still on screen (and only when the
        // Auto-Play Video Previews setting allows it).
        resumeIfWanted()
    }
}

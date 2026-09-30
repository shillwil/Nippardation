//
//  AppAudioSessionTests.swift
//  NippardationTests
//
//  The audio-session policy that keeps exercise demos from stopping the person's music:
//  Ambient (mixable) before any demo can play, never a non-mixable category. Also when a demo
//  may start by itself: only on screen, only with Auto-Play Video Previews on, and never
//  after someone paused it with the system controls.
//

import Testing
import AVFAudio
import AVFoundation
import Foundation
@testable import Nippardation

/// Records what the app asks of the audio session. Starts on Solo Ambient, the system default.
final class FakeAudioSession: AudioSessionConfigurable {
    struct Call: Equatable {
        let category: AVAudioSession.Category
        let mode: AVAudioSession.Mode
        let options: AVAudioSession.CategoryOptions
    }

    private(set) var category: AVAudioSession.Category = .soloAmbient
    private(set) var calls: [Call] = []
    var error: Error?

    func setCategory(_ category: AVAudioSession.Category,
                     mode: AVAudioSession.Mode,
                     options: AVAudioSession.CategoryOptions) throws {
        calls.append(Call(category: category, mode: mode, options: options))
        if let error { throw error }
        self.category = category
    }
}

/// Stands in for Settings › Accessibility › Motion › Auto-Play Video Previews.
final class FakeAutoplaySetting {
    var isOn: Bool

    init(isOn: Bool = true) {
        self.isOn = isOn
    }
}

@Suite("App audio session")
@MainActor
struct AppAudioSessionTests {

    @Test func switchesTheDefaultSessionToAmbient() {
        let session = FakeAudioSession()

        #expect(AppAudioSession.configure(session))
        // No .mixWithOthers (Ambient already mixes) and no .duckOthers (it would dip the music).
        #expect(session.calls == [.init(category: .ambient, mode: .default, options: [])])
        #expect(session.category == .ambient)
    }

    @Test func neverUsesANonMixableCategory() {
        let nonMixable: [AVAudioSession.Category] = [.soloAmbient, .playback, .playAndRecord, .record]
        #expect(!nonMixable.contains(AppAudioSession.category))
    }

    @Test func isIdempotent() {
        let session = FakeAudioSession()

        AppAudioSession.configure(session)
        AppAudioSession.configure(session)

        #expect(session.calls.count == 1)
    }

    @Test func reportsFailureInsteadOfThrowing() {
        let session = FakeAudioSession()
        session.error = NSError(domain: NSOSStatusErrorDomain, code: -50)

        #expect(AppAudioSession.configure(session) == false)
        #expect(session.category == .soloAmbient)
    }

    /// Hosted tests run after NippardationApp.init, which sets the real shared session.
    @Test func realSessionIsAmbientAfterLaunch() {
        #expect(AppAudioSession.configure())
        #expect(AVAudioSession.sharedInstance().category == .ambient)
    }

    // MARK: - Demo playback

    // Auto-Play Video Previews is injected as on unless a test is about it, so these don't
    // depend on the simulator's setting.

    @Test func autoplayingADemoSetsAmbientFirst() async throws {
        let cache = MockVideoCacheService()
        let remote = try #require(URL(string: "https://example.com/bench.mp4"))
        _ = try await cache.cacheVideo(for: "ex_1", from: remote)
        let session = FakeAudioSession()
        let viewModel = VideoPlayerViewModel(videoCacheService: cache, audioSession: session, isAutoplayEnabled: { true })

        await viewModel.loadVideo(exerciseServerId: "ex_1", videoUrl: remote)

        #expect(viewModel.wantsPlayback)
        #expect(session.category == .ambient)
        #expect(viewModel.player.isMuted)
    }

    @Test func playingBeforeAVideoLoadsLeavesTheSessionAlone() {
        let session = FakeAudioSession()
        let viewModel = VideoPlayerViewModel(
            videoCacheService: MockVideoCacheService(),
            audioSession: session,
            isAutoplayEnabled: { true }
        )

        viewModel.play()

        #expect(session.calls.isEmpty)
    }

    /// A download that lands after the sheet closed must not start a player nobody can see
    /// (it would still activate the audio session).
    @Test func aLateDownloadDoesNotStartPlaybackAfterPause() async throws {
        let cache = MockVideoCacheService()
        cache.setDelay(0.05)
        let session = FakeAudioSession()
        let viewModel = VideoPlayerViewModel(videoCacheService: cache, audioSession: session, isAutoplayEnabled: { true })
        let remote = try #require(URL(string: "https://example.com/dips.mp4"))

        await viewModel.loadVideo(exerciseServerId: "ex_2", videoUrl: remote)
        viewModel.pause()

        // Wait for the simulated download (and orientation probe) to finish.
        for _ in 0..<200 where viewModel.isLoading {
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(viewModel.isLoading == false)
        #expect(viewModel.wantsPlayback == false)
        #expect(session.calls.isEmpty)
    }

    // MARK: - Auto-Play Video Previews

    /// Off, the demo loads to its first frame and nothing starts it: not the load, not coming
    /// back on screen, not the app returning.
    @Test func withAutoPlayOffADemoLoadsWithoutPlaying() async throws {
        let cache = MockVideoCacheService()
        let remote = try #require(URL(string: "https://example.com/row.mp4"))
        _ = try await cache.cacheVideo(for: "ex_3", from: remote)
        let session = FakeAudioSession()
        let viewModel = VideoPlayerViewModel(videoCacheService: cache, audioSession: session, isAutoplayEnabled: { false })

        await viewModel.loadVideo(exerciseServerId: "ex_3", videoUrl: remote)
        viewModel.play()
        viewModel.resumeIfWanted()

        #expect(viewModel.wantsPlayback)
        #expect(viewModel.player.rate == 0)
        #expect(session.calls.isEmpty)
    }

    @Test func turningAutoPlayOffStopsAPlayingDemo() async throws {
        let setting = FakeAutoplaySetting()
        let id = "ex_clip_setting"
        let viewModel = try await playingDemo(id, isAutoplayEnabled: { setting.isOn })
        #expect(viewModel.player.rate > 0)

        setting.isOn = false
        viewModel.autoplaySettingDidChange()
        #expect(viewModel.player.rate == 0)

        // Stopped by the setting, not by the person: turning it back on starts the demo.
        try await letRateNotificationsLand()
        #expect(viewModel.isPausedByUser == false)

        setting.isOn = true
        viewModel.autoplaySettingDidChange()
        #expect(viewModel.player.rate > 0)
    }

    // MARK: - Pausing with the system controls

    /// Pause in the system controls sticks: scrolling away and back, the row being rebuilt and
    /// the app returning all leave the demo paused. Play in the controls clears it.
    @Test func aDemoPausedWithTheControlsStaysPaused() async throws {
        let id = "ex_clip_user_pause"
        let viewModel = try await playingDemo(id)
        #expect(viewModel.player.rate > 0)

        viewModel.player.pause()  // AVKit's Pause button
        try await waitUntil { viewModel.isPausedByUser }
        #expect(viewModel.isPausedByUser)

        viewModel.pause()
        viewModel.play()
        #expect(viewModel.player.rate == 0)

        await viewModel.loadVideo(exerciseServerId: id, videoUrl: clipURL(id))
        #expect(viewModel.player.rate == 0)

        viewModel.resumeIfWanted()
        #expect(viewModel.player.rate == 0)

        viewModel.player.play()  // AVKit's Play button
        try await waitUntil { !viewModel.isPausedByUser }
        #expect(viewModel.isPausedByUser == false)

        viewModel.pause()
        viewModel.play()
        #expect(viewModel.player.rate > 0)
    }

    /// The view model's own pause (the demo scrolled off screen) isn't the person's.
    @Test func aDemoScrolledAwayResumesWhenItComesBack() async throws {
        let id = "ex_clip_own_pause"
        let viewModel = try await playingDemo(id)

        viewModel.pause()
        #expect(viewModel.player.rate == 0)
        try await letRateNotificationsLand()
        #expect(viewModel.isPausedByUser == false)

        viewModel.play()
        #expect(viewModel.player.rate > 0)

        viewModel.pause()
        await viewModel.loadVideo(exerciseServerId: id, videoUrl: clipURL(id))  // the row rebuilt
        #expect(viewModel.player.rate > 0)
    }

    /// Interruptions and the app leaving the foreground pause the player for other reasons;
    /// the demo resumes when the app returns.
    @Test func aSystemPauseIsNotThePersons() async throws {
        let viewModel = try await playingDemo("ex_clip_system_pause")

        viewModel.player.pause()
        viewModel.playerRateDidChange(to: 0, reason: .appBackgrounded)
        viewModel.playerRateDidChange(to: 0, reason: .audioSessionInterrupted)
        #expect(viewModel.isPausedByUser == false)

        viewModel.resumeIfWanted()
        #expect(viewModel.player.rate > 0)
    }

    /// A swapped movement's demo plays, even though the last one was paused.
    @Test func aNewVideoStartsFresh() async throws {
        let cache = MockVideoCacheService()
        try await cachePlayableClip("ex_clip_first", in: cache)
        try await cachePlayableClip("ex_clip_second", in: cache)
        let viewModel = VideoPlayerViewModel(
            videoCacheService: cache,
            audioSession: FakeAudioSession(),
            isAutoplayEnabled: { true }
        )
        await viewModel.loadVideo(exerciseServerId: "ex_clip_first", videoUrl: clipURL("ex_clip_first"))
        viewModel.player.pause()
        try await waitUntil { viewModel.isPausedByUser }

        await viewModel.loadVideo(exerciseServerId: "ex_clip_second", videoUrl: clipURL("ex_clip_second"))
        // AVFoundation can report a quick stop-and-start as a second pair of changes.
        try await waitUntil { !viewModel.isPausedByUser && viewModel.player.rate > 0 }

        #expect(viewModel.isPausedByUser == false)
        #expect(viewModel.player.rate > 0)
    }

    // MARK: - Helpers

    private func clipURL(_ exerciseServerId: String) -> URL {
        URL(string: "https://example.com/\(exerciseServerId).mp4")!
    }

    /// Caches one second of silent AAC where MockVideoCacheService keeps `exerciseServerId`'s
    /// file. The player item then loads for real; a missing file would fail, set the view
    /// model's error, and block resuming for the wrong reason.
    private func cachePlayableClip(_ exerciseServerId: String, in cache: MockVideoCacheService) async throws {
        let local = try await cache.cacheVideo(for: exerciseServerId, from: clipURL(exerciseServerId))
        try FileManager.default.createDirectory(
            at: local.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: local)

        let file = try AVAudioFile(forWriting: local, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
        ])
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 44_100))
        buffer.frameLength = buffer.frameCapacity
        try file.write(from: buffer)
        file.close()
    }

    /// A view model playing a real clip, as a demo does once its view is on screen.
    private func playingDemo(
        _ exerciseServerId: String,
        isAutoplayEnabled: @escaping @MainActor () -> Bool = { true }
    ) async throws -> VideoPlayerViewModel {
        let cache = MockVideoCacheService()
        try await cachePlayableClip(exerciseServerId, in: cache)
        let viewModel = VideoPlayerViewModel(
            videoCacheService: cache,
            audioSession: FakeAudioSession(),
            isAutoplayEnabled: isAutoplayEnabled
        )
        await viewModel.loadVideo(exerciseServerId: exerciseServerId, videoUrl: clipURL(exerciseServerId))
        return viewModel
    }

    /// The view model hears about rate changes on the main queue, a beat after they happen.
    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<200 where !condition() {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    /// A rate change that should change nothing leaves no condition to wait for: give it a moment.
    private func letRateNotificationsLand() async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }
}

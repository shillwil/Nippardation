//
//  AppAudioSession.swift
//  Nippardation
//
//  The app's audio-session policy. Exercise demos are silent, nonessential visuals, so the
//  session is Ambient (HIG › Playing audio: "Sound isn't essential, and it doesn't silence
//  other audio"). Left alone, iOS uses Solo Ambient, which stops the person's music the
//  moment any AVPlayer starts — muted or not, because every demo file carries a silent
//  audio track.
//

import AVFAudio

/// The part of `AVAudioSession` the app configures, so tests can inject a fake.
protocol AudioSessionConfigurable: AnyObject {
    var category: AVAudioSession.Category { get }
    func setCategory(_ category: AVAudioSession.Category,
                     mode: AVAudioSession.Mode,
                     options: AVAudioSession.CategoryOptions) throws
}

extension AVAudioSession: AudioSessionConfigurable {}

enum AppAudioSession {
    static let category: AVAudioSession.Category = .ambient
    static let mode: AVAudioSession.Mode = .default

    /// Sets Ambient unless it's already set. Never activates the session: AVPlayer does that
    /// when a demo starts, and an Ambient activation mixes with other audio instead of
    /// interrupting it. Idempotent; a failure is logged and reported, never thrown.
    @discardableResult
    static func configure(_ session: any AudioSessionConfigurable = AVAudioSession.sharedInstance()) -> Bool {
        if session.category == category { return true }
        do {
            // No .mixWithOthers: Ambient already mixes, and the SDK documents that option as
            // valid only with .playback, .playAndRecord and .multiRoute.
            try session.setCategory(category, mode: mode, options: [])
            return true
        } catch {
            print("[AudioSession] Could not set \(category.rawValue): \(error)")
            return false
        }
    }
}

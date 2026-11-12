//
//  AudioSessionTests.swift
//  NippardationTests
//
//  Exercise demo videos must never pause the user's music (Spotify, Apple Music, ...).
//

import AVFoundation
import Testing
@testable import Nippardation

struct AudioSessionTests {

    @Test func audioSessionMixesWithOtherAppsAudio() {
        NippardationApp.configureAudioSession()

        #expect(AVAudioSession.sharedInstance().category == .ambient)
    }
}

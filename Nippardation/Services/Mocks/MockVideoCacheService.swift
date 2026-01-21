//
//  MockVideoCacheService.swift
//  Nippardation
//
//  Phase 0: Mock implementation of VideoCacheServiceProtocol for testing and previews
//

import Foundation
import Combine

/// Mock implementation of VideoCacheServiceProtocol
/// Simulates video caching behavior for testing and previews
@MainActor
final class MockVideoCacheService: VideoCacheServiceProtocol {

    // MARK: - Properties

    private let progressSubject = PassthroughSubject<VideoDownloadProgress, Never>()
    var downloadProgressPublisher: AnyPublisher<VideoDownloadProgress, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    private(set) var totalCacheSize: Int64 = 0
    let maxCacheSize: Int64 = 500 * 1024 * 1024 // 500 MB

    // MARK: - Mock State

    private var cachedVideos: [String: CachedVideo] = [:]
    private var shouldFail = false
    private var simulatedDelay: TimeInterval = 0

    private struct CachedVideo {
        let localURL: URL
        let remoteURL: URL
        let size: Int64
        var lastAccessed: Date
    }

    // MARK: - Configuration

    func setFailure(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func setDelay(_ delay: TimeInterval) {
        self.simulatedDelay = delay
    }

    // MARK: - VideoCacheServiceProtocol

    func getCachedVideoURL(for exerciseServerId: String) -> URL? {
        cachedVideos[exerciseServerId]?.localURL
    }

    func isVideoCached(for exerciseServerId: String) -> Bool {
        cachedVideos[exerciseServerId] != nil
    }

    func cacheVideo(for exerciseServerId: String, from remoteURL: URL) async throws -> URL {
        if shouldFail {
            throw VideoCacheError.downloadFailed(remoteURL, NSError(domain: "MockError", code: -1))
        }

        // Simulate download progress
        let totalBytes: Int64 = 10 * 1024 * 1024 // 10 MB simulated size

        if simulatedDelay > 0 {
            // Send progress updates
            for progress in stride(from: 0, through: 100, by: 25) {
                progressSubject.send(VideoDownloadProgress(
                    exerciseServerId: exerciseServerId,
                    state: .downloading,
                    bytesDownloaded: Int64(progress) * totalBytes / 100,
                    totalBytes: totalBytes
                ))
                try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000 / 4))
            }
        }

        // Create mock local URL
        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("videos")
            .appendingPathComponent("\(exerciseServerId).mp4")

        cachedVideos[exerciseServerId] = CachedVideo(
            localURL: localURL,
            remoteURL: remoteURL,
            size: totalBytes,
            lastAccessed: Date()
        )
        totalCacheSize += totalBytes

        progressSubject.send(VideoDownloadProgress(
            exerciseServerId: exerciseServerId,
            state: .completed,
            bytesDownloaded: totalBytes,
            totalBytes: totalBytes
        ))

        return localURL
    }

    func removeCachedVideo(for exerciseServerId: String) async throws {
        if let video = cachedVideos.removeValue(forKey: exerciseServerId) {
            totalCacheSize -= video.size
        }
    }

    func clearCache() async throws {
        cachedVideos.removeAll()
        totalCacheSize = 0
    }

    func prefetchVideos(for templateServerId: String) async {
        // Mock: pretend to prefetch videos
        // In real implementation, this would fetch the template's exercises and cache their videos
    }

    func prefetchVideosForActiveProgram() async {
        // Mock: pretend to prefetch videos for active program
    }

    func cancelPrefetch() {
        // No-op for mock
    }

    func evictIfNeeded() async throws {
        while totalCacheSize > maxCacheSize {
            // Find oldest accessed video
            guard let oldest = cachedVideos.min(by: { $0.value.lastAccessed < $1.value.lastAccessed }) else {
                break
            }
            try await removeCachedVideo(for: oldest.key)
        }
    }

    func getCacheStats() -> VideoCacheStats {
        let oldestAccess = cachedVideos.values.min { $0.lastAccessed < $1.lastAccessed }?.lastAccessed
        let newestAccess = cachedVideos.values.max { $0.lastAccessed < $1.lastAccessed }?.lastAccessed

        return VideoCacheStats(
            totalSize: totalCacheSize,
            maxSize: maxCacheSize,
            videoCount: cachedVideos.count,
            oldestAccessDate: oldestAccess,
            newestAccessDate: newestAccess
        )
    }

    func touchVideo(for exerciseServerId: String) async {
        cachedVideos[exerciseServerId]?.lastAccessed = Date()
    }

    // MARK: - Test Helpers

    /// Pre-populates cache with mock data
    func populateWithMockData() {
        let mockVideos = [
            ("ex_001", "https://example.com/videos/bench.mp4"),
            ("ex_002", "https://example.com/videos/squat.mp4"),
            ("ex_003", "https://example.com/videos/deadlift.mp4")
        ]

        for (id, urlString) in mockVideos {
            guard let url = URL(string: urlString) else { continue }
            let localURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("videos")
                .appendingPathComponent("\(id).mp4")

            let size: Int64 = Int64.random(in: 5_000_000...15_000_000)
            cachedVideos[id] = CachedVideo(
                localURL: localURL,
                remoteURL: url,
                size: size,
                lastAccessed: Date()
            )
            totalCacheSize += size
        }
    }
}

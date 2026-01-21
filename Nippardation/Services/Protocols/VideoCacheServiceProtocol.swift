//
//  VideoCacheServiceProtocol.swift
//  Nippardation
//
//  Phase 0: Protocol defining video cache service operations
//

import Foundation
import Combine

/// Protocol defining operations for caching exercise videos
@MainActor
protocol VideoCacheServiceProtocol {

    // MARK: - Properties

    /// Publisher for download progress updates
    var downloadProgressPublisher: AnyPublisher<VideoDownloadProgress, Never> { get }

    /// Total cache size in bytes
    var totalCacheSize: Int64 { get }

    /// Maximum allowed cache size in bytes
    var maxCacheSize: Int64 { get }

    // MARK: - Cache Operations

    /// Gets the local URL for a cached video
    /// - Parameter exerciseServerId: The server ID of the exercise
    /// - Returns: Local file URL if cached, nil otherwise
    func getCachedVideoURL(for exerciseServerId: String) -> URL?

    /// Checks if a video is cached
    /// - Parameter exerciseServerId: The server ID of the exercise
    /// - Returns: True if the video is cached
    func isVideoCached(for exerciseServerId: String) -> Bool

    /// Downloads and caches a video for an exercise
    /// - Parameters:
    ///   - exerciseServerId: The server ID of the exercise
    ///   - remoteURL: The remote URL of the video
    /// - Returns: Local file URL after caching
    func cacheVideo(
        for exerciseServerId: String,
        from remoteURL: URL
    ) async throws -> URL

    /// Removes a cached video
    /// - Parameter exerciseServerId: The server ID of the exercise
    func removeCachedVideo(for exerciseServerId: String) async throws

    /// Clears all cached videos
    func clearCache() async throws

    // MARK: - Prefetching

    /// Prefetches videos for exercises in a template
    /// - Parameter templateServerId: The server ID of the template
    func prefetchVideos(for templateServerId: String) async

    /// Prefetches videos for all exercises in the active program
    func prefetchVideosForActiveProgram() async

    /// Cancels any ongoing prefetch operations
    func cancelPrefetch()

    // MARK: - Cache Management

    /// Evicts old videos to stay under cache limit (LRU)
    func evictIfNeeded() async throws

    /// Returns cache statistics
    func getCacheStats() -> VideoCacheStats

    /// Updates the access time for a video (for LRU tracking)
    /// - Parameter exerciseServerId: The server ID of the exercise
    func touchVideo(for exerciseServerId: String) async
}

// MARK: - Supporting Types

/// Progress information for video downloads
struct VideoDownloadProgress: Equatable {
    let exerciseServerId: String
    let state: DownloadState
    let bytesDownloaded: Int64
    let totalBytes: Int64

    var fractionComplete: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesDownloaded) / Double(totalBytes)
    }

    enum DownloadState: Equatable {
        case queued
        case downloading
        case completed
        case failed(String)
        case cancelled
    }
}

/// Statistics about the video cache
struct VideoCacheStats {
    let totalSize: Int64
    let maxSize: Int64
    let videoCount: Int
    let oldestAccessDate: Date?
    let newestAccessDate: Date?

    var usagePercentage: Double {
        guard maxSize > 0 else { return 0 }
        return Double(totalSize) / Double(maxSize)
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var formattedMaxSize: String {
        ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)
    }

    var formattedAvailableSpace: String {
        ByteCountFormatter.string(fromByteCount: maxSize - totalSize, countStyle: .file)
    }
}

/// Error types for video caching
enum VideoCacheError: LocalizedError {
    case downloadFailed(URL, Error)
    case insufficientSpace(required: Int64, available: Int64)
    case invalidURL(String)
    case fileNotFound(String)
    case cacheCorrupted

    var errorDescription: String? {
        switch self {
        case .downloadFailed(let url, let error):
            return "Failed to download video from \(url.absoluteString): \(error.localizedDescription)"
        case .insufficientSpace(let required, let available):
            let requiredStr = ByteCountFormatter.string(fromByteCount: required, countStyle: .file)
            let availableStr = ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
            return "Not enough space. Required: \(requiredStr), Available: \(availableStr)"
        case .invalidURL(let url):
            return "Invalid video URL: \(url)"
        case .fileNotFound(let id):
            return "Cached video not found for exercise: \(id)"
        case .cacheCorrupted:
            return "Video cache is corrupted. Please clear cache and try again."
        }
    }
}

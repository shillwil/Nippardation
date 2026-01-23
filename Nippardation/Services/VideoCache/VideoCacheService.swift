//
//  VideoCacheService.swift
//  Nippardation
//
//  Concrete implementation of VideoCacheServiceProtocol
//  Manages local video caching with LRU eviction
//

import Foundation
import Combine

/// Concrete implementation of VideoCacheServiceProtocol
/// Manages local video caching with LRU eviction
@MainActor
final class VideoCacheService: VideoCacheServiceProtocol {

    // MARK: - Constants

    /// Maximum cache size in bytes (500 MB)
    private let _maxCacheSize: Int64 = 500 * 1024 * 1024

    /// Cache directory name
    private let cacheDirectoryName = "VideoCache"

    // MARK: - Dependencies

    private let downloadManager: VideoDownloadManager
    private let fileManager: FileManager
    private let templateRepository: any TemplateRepositoryProtocol
    private let programRepository: any ProgramRepositoryProtocol

    // MARK: - State

    private let _downloadProgress = PassthroughSubject<VideoDownloadProgress, Never>()

    /// In-memory index of cached videos
    private var cacheIndex: [String: CacheEntry] = [:]

    private struct CacheEntry: Codable {
        let exerciseServerId: String
        let localPath: String
        let fileSize: Int64
        var lastAccessedAt: Date
    }

    // MARK: - Protocol Properties

    var downloadProgressPublisher: AnyPublisher<VideoDownloadProgress, Never> {
        _downloadProgress.eraseToAnyPublisher()
    }

    var totalCacheSize: Int64 {
        cacheIndex.values.reduce(0) { $0 + $1.fileSize }
    }

    var maxCacheSize: Int64 {
        _maxCacheSize
    }

    // MARK: - Computed Properties

    private var cacheDirectory: URL {
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDir.appendingPathComponent(cacheDirectoryName)
    }

    private var cacheIndexURL: URL {
        cacheDirectory.appendingPathComponent("cache_index.json")
    }

    // MARK: - Initialization

    init(
        downloadManager: VideoDownloadManager = VideoDownloadManager(),
        fileManager: FileManager = .default,
        templateRepository: (any TemplateRepositoryProtocol)? = nil,
        programRepository: (any ProgramRepositoryProtocol)? = nil
    ) {
        self.downloadManager = downloadManager
        self.fileManager = fileManager
        self.templateRepository = templateRepository ?? DependencyContainer.shared.templateRepository
        self.programRepository = programRepository ?? DependencyContainer.shared.programRepository

        // Ensure cache directory exists
        createCacheDirectoryIfNeeded()

        // Load cache index from disk
        loadCacheIndex()

        // Set up download progress forwarding
        Task {
            await downloadManager.setProgressHandler { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?._downloadProgress.send(progress)
                }
            }
        }
    }

    // MARK: - Cache Operations

    func getCachedVideoURL(for exerciseServerId: String) -> URL? {
        guard let entry = cacheIndex[exerciseServerId] else {
            return nil
        }

        // Verify file exists
        if fileManager.fileExists(atPath: entry.localPath) {
            return URL(fileURLWithPath: entry.localPath)
        } else {
            // File was deleted externally, remove from index
            cacheIndex.removeValue(forKey: exerciseServerId)
            saveCacheIndex()
            return nil
        }
    }

    func isVideoCached(for exerciseServerId: String) -> Bool {
        guard let entry = cacheIndex[exerciseServerId] else {
            return false
        }
        return fileManager.fileExists(atPath: entry.localPath)
    }

    func cacheVideo(for exerciseServerId: String, from remoteURL: URL) async throws -> URL {
        // Check if already cached
        if let localURL = getCachedVideoURL(for: exerciseServerId) {
            await touchVideo(for: exerciseServerId)
            return localURL
        }

        // Determine local URL
        let localURL = localURLFor(exerciseServerId: exerciseServerId)

        // Download the video
        let resultURL = try await downloadManager.download(
            exerciseServerId: exerciseServerId,
            remoteURL: remoteURL,
            localURL: localURL
        )

        // Get file size and add to cache index
        if let fileSize = fileSizeAt(resultURL) {
            cacheIndex[exerciseServerId] = CacheEntry(
                exerciseServerId: exerciseServerId,
                localPath: resultURL.path,
                fileSize: fileSize,
                lastAccessedAt: Date()
            )
            saveCacheIndex()

            // Check if we need to evict
            try await evictIfNeeded()
        }

        return resultURL
    }

    func removeCachedVideo(for exerciseServerId: String) async throws {
        guard let entry = cacheIndex[exerciseServerId] else {
            return
        }

        // Remove file
        let url = URL(fileURLWithPath: entry.localPath)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }

        // Remove from index
        cacheIndex.removeValue(forKey: exerciseServerId)
        saveCacheIndex()
    }

    func clearCache() async throws {
        // Cancel any active downloads
        await downloadManager.cancelAll()

        // Clear the index
        cacheIndex.removeAll()

        // Delete all files in cache directory
        if fileManager.fileExists(atPath: cacheDirectory.path) {
            let contents = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: nil
            )
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        }

        // Save empty index
        saveCacheIndex()
    }

    // MARK: - Prefetching

    func prefetchVideos(for templateServerId: String) async {
        let task = Task {
            do {
                // Get template from repository
                let template = try await templateRepository.fetchTemplate(serverId: templateServerId)

                // Download videos for each exercise that has a video URL
                for templateExercise in template.exercises {
                    // Check for cancellation
                    if Task.isCancelled { break }

                    // Get exercise details - use exerciseServerId as cache key
                    if let exerciseItem = templateExercise.exerciseLibraryItem,
                       let videoUrl = exerciseItem.videoUrl,
                       !isVideoCached(for: templateExercise.exerciseServerId) {
                        _ = try? await cacheVideo(for: templateExercise.exerciseServerId, from: videoUrl)
                    }
                }
            } catch {
                // Silently fail prefetch - it's an optimization
            }
        }

        await downloadManager.setPrefetchTask(task)
        await task.value
    }

    func prefetchVideosForActiveProgram() async {
        let task = Task {
            do {
                // Get active program
                guard let activeProgram = try await programRepository.getActiveProgram() else {
                    return
                }

                // Prefetch videos for each workout's template in the program
                for programWorkout in activeProgram.workouts {
                    if Task.isCancelled { break }

                    // Fetch the template if not already resolved
                    let template: Template
                    if let resolvedTemplate = programWorkout.template {
                        template = resolvedTemplate
                    } else {
                        template = try await templateRepository.fetchTemplate(serverId: programWorkout.templateServerId)
                    }

                    // Download videos for each exercise
                    for templateExercise in template.exercises {
                        if Task.isCancelled { break }

                        if let exerciseItem = templateExercise.exerciseLibraryItem,
                           let videoUrl = exerciseItem.videoUrl,
                           !isVideoCached(for: templateExercise.exerciseServerId) {
                            _ = try? await cacheVideo(for: templateExercise.exerciseServerId, from: videoUrl)
                        }
                    }
                }
            } catch {
                // Silently fail prefetch
            }
        }

        await downloadManager.setPrefetchTask(task)
        await task.value
    }

    func cancelPrefetch() {
        Task {
            await downloadManager.cancelPrefetch()
        }
    }

    // MARK: - Cache Management

    func evictIfNeeded() async throws {
        guard totalCacheSize > _maxCacheSize else { return }

        // Target 80% of max size
        let targetSize = Int64(Double(_maxCacheSize) * 0.8)
        try await evictToSize(targetSize)
    }

    func getCacheStats() -> VideoCacheStats {
        let sortedEntries = cacheIndex.values.sorted { $0.lastAccessedAt < $1.lastAccessedAt }

        return VideoCacheStats(
            totalSize: totalCacheSize,
            maxSize: _maxCacheSize,
            videoCount: cacheIndex.count,
            oldestAccessDate: sortedEntries.first?.lastAccessedAt,
            newestAccessDate: sortedEntries.last?.lastAccessedAt
        )
    }

    func touchVideo(for exerciseServerId: String) async {
        guard cacheIndex[exerciseServerId] != nil else { return }
        cacheIndex[exerciseServerId]?.lastAccessedAt = Date()
        saveCacheIndex()
    }

    // MARK: - Private Helpers

    private func localURLFor(exerciseServerId: String) -> URL {
        // Sanitize the serverId for use as a filename
        let sanitized = exerciseServerId.replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent("\(sanitized).mp4")
    }

    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    private func fileSizeAt(_ url: URL) -> Int64? {
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? NSNumber else {
            return nil
        }
        return size.int64Value
    }

    private func evictToSize(_ targetBytes: Int64) async throws {
        // Sort by last accessed (oldest first) for LRU eviction
        var entries = cacheIndex.values.sorted { $0.lastAccessedAt < $1.lastAccessedAt }
        var currentSize = totalCacheSize

        // Remove oldest entries until under target
        while currentSize > targetBytes && !entries.isEmpty {
            let oldest = entries.removeFirst()

            // Delete file
            let url = URL(fileURLWithPath: oldest.localPath)
            try? fileManager.removeItem(at: url)

            // Update index
            cacheIndex.removeValue(forKey: oldest.exerciseServerId)
            currentSize -= oldest.fileSize
        }

        saveCacheIndex()
    }

    // MARK: - Persistence

    private func loadCacheIndex() {
        guard fileManager.fileExists(atPath: cacheIndexURL.path),
              let data = try? Data(contentsOf: cacheIndexURL),
              let savedEntries = try? JSONDecoder().decode([CacheEntry].self, from: data) else {
            return
        }

        // Verify files exist before adding to index
        for entry in savedEntries {
            if fileManager.fileExists(atPath: entry.localPath) {
                cacheIndex[entry.exerciseServerId] = entry
            }
        }
    }

    private func saveCacheIndex() {
        let entries = Array(cacheIndex.values)
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: cacheIndexURL)
    }
}

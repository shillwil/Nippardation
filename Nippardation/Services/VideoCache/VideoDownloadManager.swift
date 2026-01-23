//
//  VideoDownloadManager.swift
//  Nippardation
//
//  Manages video file downloads with progress tracking
//

import Foundation

/// Manages video file downloads with progress tracking
actor VideoDownloadManager {

    // MARK: - Types

    struct ActiveDownload {
        let exerciseServerId: String
        let remoteURL: URL
        let localURL: URL
        var bytesDownloaded: Int64 = 0
        var totalBytes: Int64 = 0
    }

    // MARK: - State

    private var activeDownloads: [String: ActiveDownload] = [:]
    private var activeSessions: [String: URLSession] = [:] // Track sessions for cancellation
    private var progressHandler: ((VideoDownloadProgress) -> Void)?
    private var prefetchTask: Task<Void, Never>?

    // MARK: - Configuration

    func setProgressHandler(_ handler: @escaping (VideoDownloadProgress) -> Void) {
        self.progressHandler = handler
    }

    // MARK: - Download Operations

    /// Download a video file with progress tracking
    /// - Parameters:
    ///   - exerciseServerId: Server ID of the exercise (used as cache key)
    ///   - remoteURL: Remote video URL
    ///   - localURL: Local destination URL
    /// - Returns: Local file URL after download completes
    func download(
        exerciseServerId: String,
        remoteURL: URL,
        localURL: URL
    ) async throws -> URL {
        // Check if already downloading
        if activeDownloads[exerciseServerId] != nil {
            return try await waitForExistingDownload(exerciseServerId: exerciseServerId, localURL: localURL)
        }

        // Track this download
        activeDownloads[exerciseServerId] = ActiveDownload(
            exerciseServerId: exerciseServerId,
            remoteURL: remoteURL,
            localURL: localURL
        )

        // Report queued state
        reportProgress(exerciseServerId: exerciseServerId, state: .queued, bytesDownloaded: 0, totalBytes: 0)

        defer {
            activeDownloads.removeValue(forKey: exerciseServerId)
        }

        do {
            // Create delegate for progress tracking
            let delegate = DownloadProgressDelegate(
                exerciseServerId: exerciseServerId,
                progressHandler: { [weak self] serverId, bytesDownloaded, totalBytes in
                    Task { [weak self] in
                        await self?.updateProgress(
                            exerciseServerId: serverId,
                            bytesDownloaded: bytesDownloaded,
                            totalBytes: totalBytes
                        )
                    }
                }
            )

            let session = URLSession(
                configuration: .default,
                delegate: delegate,
                delegateQueue: nil
            )

            // Track session for potential cancellation
            activeSessions[exerciseServerId] = session

            defer {
                activeSessions.removeValue(forKey: exerciseServerId)
                session.finishTasksAndInvalidate()
            }

            // Report downloading state
            reportProgress(exerciseServerId: exerciseServerId, state: .downloading, bytesDownloaded: 0, totalBytes: 0)

            // Perform download
            let (tempURL, response) = try await session.download(from: remoteURL, delegate: delegate)

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw VideoCacheError.downloadFailed(
                    remoteURL,
                    NSError(domain: "HTTP", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode)"])
                )
            }

            // Move to final location
            try await moveToFinalLocation(from: tempURL, to: localURL)

            // Get file size for final progress report
            let fileSize = (try FileManager.default.attributesOfItem(atPath: localURL.path)[.size] as? NSNumber)?.int64Value ?? 0

            // Report completion
            reportProgress(exerciseServerId: exerciseServerId, state: .completed, bytesDownloaded: fileSize, totalBytes: fileSize)

            return localURL

        } catch {
            // Report failure
            reportProgress(
                exerciseServerId: exerciseServerId,
                state: .failed(error.localizedDescription),
                bytesDownloaded: 0,
                totalBytes: 0
            )
            throw error
        }
    }

    /// Cancel all active downloads
    func cancelAll() {
        prefetchTask?.cancel()
        prefetchTask = nil

        // Cancel all active URLSessions
        for (exerciseServerId, session) in activeSessions {
            session.invalidateAndCancel()
            reportProgress(exerciseServerId: exerciseServerId, state: .cancelled, bytesDownloaded: 0, totalBytes: 0)
        }
        activeSessions.removeAll()
        activeDownloads.removeAll()
    }

    /// Cancel download for specific exercise
    func cancel(exerciseServerId: String) {
        // Cancel the URLSession if it exists
        if let session = activeSessions[exerciseServerId] {
            session.invalidateAndCancel()
            activeSessions.removeValue(forKey: exerciseServerId)
        }

        if activeDownloads[exerciseServerId] != nil {
            reportProgress(exerciseServerId: exerciseServerId, state: .cancelled, bytesDownloaded: 0, totalBytes: 0)
            activeDownloads.removeValue(forKey: exerciseServerId)
        }
    }

    /// Check if a download is in progress
    func isDownloading(exerciseServerId: String) -> Bool {
        return activeDownloads[exerciseServerId] != nil
    }

    // MARK: - Prefetch Support

    /// Set the prefetch task for cancellation tracking
    func setPrefetchTask(_ task: Task<Void, Never>) {
        prefetchTask = task
    }

    /// Cancel prefetch operations
    func cancelPrefetch() {
        prefetchTask?.cancel()
        prefetchTask = nil
    }

    // MARK: - Private Helpers

    private func waitForExistingDownload(exerciseServerId: String, localURL: URL) async throws -> URL {
        // Poll until download completes
        while activeDownloads[exerciseServerId] != nil {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }

        // Check if file exists
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        } else {
            throw VideoCacheError.downloadFailed(
                localURL,
                NSError(domain: "Download", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download was cancelled or failed"])
            )
        }
    }

    private func updateProgress(exerciseServerId: String, bytesDownloaded: Int64, totalBytes: Int64) {
        activeDownloads[exerciseServerId]?.bytesDownloaded = bytesDownloaded
        activeDownloads[exerciseServerId]?.totalBytes = totalBytes
        reportProgress(
            exerciseServerId: exerciseServerId,
            state: .downloading,
            bytesDownloaded: bytesDownloaded,
            totalBytes: totalBytes
        )
    }

    private func reportProgress(exerciseServerId: String, state: VideoDownloadProgress.DownloadState, bytesDownloaded: Int64, totalBytes: Int64) {
        let progress = VideoDownloadProgress(
            exerciseServerId: exerciseServerId,
            state: state,
            bytesDownloaded: bytesDownloaded,
            totalBytes: totalBytes
        )
        progressHandler?(progress)
    }

    private func moveToFinalLocation(from tempURL: URL, to localURL: URL) async throws {
        let fileManager = FileManager.default

        // Create directory if needed
        let directory = localURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        // Remove existing file if present
        if fileManager.fileExists(atPath: localURL.path) {
            try fileManager.removeItem(at: localURL)
        }

        // Move temp file to final location
        try fileManager.moveItem(at: tempURL, to: localURL)
    }
}

// MARK: - Download Progress Delegate

private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    let exerciseServerId: String
    let progressHandler: (String, Int64, Int64) -> Void

    init(
        exerciseServerId: String,
        progressHandler: @escaping (String, Int64, Int64) -> Void
    ) {
        self.exerciseServerId = exerciseServerId
        self.progressHandler = progressHandler
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // File handling is done in the main download method
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        progressHandler(exerciseServerId, totalBytesWritten, totalBytesExpectedToWrite)
    }
}

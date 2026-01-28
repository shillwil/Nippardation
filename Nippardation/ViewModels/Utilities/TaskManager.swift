//
//  TaskManager.swift
//  Nippardation
//
//  Utility for managing async tasks with cancellation support
//

import Foundation

/// Actor-based task manager for handling async operations with automatic cancellation
/// Use this to ensure only one instance of a named task runs at a time
actor TaskManager {

    // MARK: - Properties

    private var tasks: [String: Task<Void, Never>] = [:]

    // MARK: - Public Methods

    /// Runs an async operation, cancelling any existing task with the same ID
    /// - Parameters:
    ///   - id: Unique identifier for this task
    ///   - operation: The async operation to perform
    func run(id: String, operation: @escaping @Sendable () async -> Void) {
        // Cancel existing task with same ID
        tasks[id]?.cancel()

        // Create and store new task
        tasks[id] = Task {
            await operation()
        }
    }

    /// Runs an async throwing operation, cancelling any existing task with the same ID
    /// - Parameters:
    ///   - id: Unique identifier for this task
    ///   - operation: The async throwing operation to perform
    func runThrowing(id: String, operation: @escaping @Sendable () async throws -> Void) {
        // Cancel existing task with same ID
        tasks[id]?.cancel()

        // Create and store new task
        tasks[id] = Task {
            do {
                try await operation()
            } catch {
                // Task was cancelled or failed - logged for debugging
                if !(error is CancellationError) {
                    print("TaskManager: Task '\(id)' failed with error: \(error)")
                }
            }
        }
    }

    /// Cancels a specific task by ID
    /// - Parameter id: The task ID to cancel
    func cancel(id: String) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }

    /// Cancels all running tasks
    func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }

}

// MARK: - MainActor Convenience Extension

extension TaskManager {

    /// Convenience method for running MainActor-isolated operations
    /// - Parameters:
    ///   - id: Unique identifier for this task
    ///   - operation: The MainActor-isolated async operation to perform
    @MainActor
    func runOnMain(id: String, operation: @escaping @MainActor () async -> Void) async {
        await run(id: id) {
            await operation()
        }
    }
}

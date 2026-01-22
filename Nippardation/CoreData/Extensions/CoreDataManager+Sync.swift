//
//  CoreDataManager+Sync.swift
//  Nippardation
//
//  Extension for sync-related operations
//

import Foundation
import CoreData

// MARK: - Sync Operations

extension CoreDataManager {

    // MARK: - Sync Status Constants

    /// Sync status values for Core Data entities
    enum SyncStatusValue: Int16 {
        case unsynced = 0
        case syncing = 1
        case synced = 2
    }

    // MARK: - Workout Sync Operations

    /// Fetch workouts that need to be synced
    func fetchUnsyncedWorkouts() -> [CDTrackedWorkout] {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus != %d", SyncStatusValue.synced.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch unsynced workouts: \(error)")
            return []
        }
    }

    /// Fetch workouts by sync status
    func fetchWorkouts(withSyncStatus status: SyncStatusValue) -> [CDTrackedWorkout] {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %d", status.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch workouts with status \(status): \(error)")
            return []
        }
    }

    /// Fetch workout by server ID
    func fetchWorkout(serverId: String) -> CDTrackedWorkout? {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "serverId == %@", serverId)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Failed to fetch workout by server ID: \(error)")
            return nil
        }
    }

    /// Mark workouts as synced
    func markWorkoutsAsSynced(_ localIds: [UUID], serverIds: [String]) async throws {
        guard localIds.count == serverIds.count else {
            throw RepositoryError.validationError("Mismatched ID counts")
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                do {
                    for (index, localId) in localIds.enumerated() {
                        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
                        request.predicate = NSPredicate(format: "id == %@", localId as CVarArg)
                        request.fetchLimit = 1

                        if let workout = try context.fetch(request).first {
                            workout.serverId = serverIds[index]
                            workout.syncStatus = SyncStatusValue.synced.rawValue
                            workout.lastSyncedAt = Date()
                        }
                    }

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Mark a single workout as synced
    func markWorkoutSynced(localId: UUID, serverId: String) async throws {
        try await markWorkoutsAsSynced([localId], serverIds: [serverId])
    }

    /// Update sync status for a workout
    func updateWorkoutSyncStatus(localId: UUID, status: SyncStatusValue) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", localId as CVarArg)
                request.fetchLimit = 1

                do {
                    if let workout = try context.fetch(request).first {
                        workout.syncStatus = status.rawValue
                        if status == .synced {
                            workout.lastSyncedAt = Date()
                        }
                    }
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: RepositoryError.storageError(error))
                }
            }
        }
    }

    /// Get sync status for a workout
    func getWorkoutSyncStatus(localId: UUID) -> WorkoutSyncStatus {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", localId as CVarArg)
        request.fetchLimit = 1

        do {
            guard let workout = try viewContext.fetch(request).first else {
                return .pending
            }

            switch workout.syncStatus {
            case SyncStatusValue.synced.rawValue:
                return .synced
            case SyncStatusValue.syncing.rawValue:
                return .syncing
            default:
                return .pending
            }
        } catch {
            return .failed(error)
        }
    }

    // MARK: - Pending Changes Count

    /// Get count of pending changes by type
    func getPendingChangesCount() -> PendingChanges {
        let workoutCount = fetchUnsyncedWorkouts().count
        let templateCount = fetchPendingTemplates().count
        let programCount = fetchPendingPrograms().count

        return PendingChanges(
            workouts: workoutCount,
            templates: templateCount,
            programs: programCount
        )
    }

    // MARK: - Sync Timestamp Management

    private static let lastSyncTimestampKey = "lastSyncTimestamp"

    /// Get the last sync timestamp
    func getLastSyncTimestamp() -> Date? {
        return UserDefaults.standard.object(forKey: Self.lastSyncTimestampKey) as? Date
    }

    /// Set the last sync timestamp
    func setLastSyncTimestamp(_ date: Date) {
        UserDefaults.standard.set(date, forKey: Self.lastSyncTimestampKey)
    }

    // MARK: - Workouts by Date Range

    /// Fetch workouts within a date range
    func fetchWorkouts(from startDate: Date, to endDate: Date) -> [CDTrackedWorkout] {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch workouts in date range: \(error)")
            return []
        }
    }

    /// Fetch workouts with pagination
    func fetchWorkouts(page: Int, limit: Int, startDate: Date?, endDate: Date?) -> [CDTrackedWorkout] {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()

        var predicates: [NSPredicate] = []
        if let startDate = startDate {
            predicates.append(NSPredicate(format: "date >= %@", startDate as NSDate))
        }
        if let endDate = endDate {
            predicates.append(NSPredicate(format: "date <= %@", endDate as NSDate))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchOffset = (page - 1) * limit
        request.fetchLimit = limit

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch workouts with pagination: \(error)")
            return []
        }
    }

    /// Get total workout count (for pagination)
    func getWorkoutCount(startDate: Date?, endDate: Date?) -> Int {
        let request: NSFetchRequest<CDTrackedWorkout> = CDTrackedWorkout.fetchRequest()

        var predicates: [NSPredicate] = []
        if let startDate = startDate {
            predicates.append(NSPredicate(format: "date >= %@", startDate as NSDate))
        }
        if let endDate = endDate {
            predicates.append(NSPredicate(format: "date <= %@", endDate as NSDate))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        do {
            return try viewContext.count(for: request)
        } catch {
            print("Failed to get workout count: \(error)")
            return 0
        }
    }
}

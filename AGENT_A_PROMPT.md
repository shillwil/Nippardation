# Agent A: Networking/API Layer Implementation

## Overview

You are Agent A, responsible for implementing the **API Service Layer** for the Nippardation iOS fitness app. Your services make HTTP requests to the backend and return typed DTOs to the repository layer.

**Your deliverables:**
1. `Services/API/ExerciseAPIService.swift`
2. `Services/API/TemplateAPIService.swift`
3. `Services/API/ProgramAPIService.swift`
4. `Services/API/SyncAPIService.swift`
5. `Services/API/UserAPIService.swift`
6. `Services/Utilities/JSONCoders.swift` (shared encoder/decoder)
7. Extension to `ExerciseFilters` for query item conversion

---

## Critical Constraints

### DO NOT Modify These Files
The following Phase 0 files are shared by other agents and must not be altered:
- `Services/Protocols/*Protocol.swift`
- `Models/API/*.swift`
- `Models/Errors/RepositoryError.swift`
- `Services/DependencyContainer.swift`

### Must Use Existing Types
Your implementations must use these existing types exactly as defined:

**Response Types** (from `Models/API/`):
- `ExerciseListResponse` - contains `exercises: [ExerciseDTO]` and `pagination: PaginationDTO`
- `ExerciseDetailResponse` - contains `exercise: ExerciseDTO`
- `TemplateListResponse` - contains `templates: [TemplateDTO]` and `pagination: PaginationDTO`
- `TemplateDetailResponse` - contains `template: TemplateDTO`
- `ProgramListResponse` - contains `programs: [ProgramDTO]` and `pagination: PaginationDTO`
- `ProgramDetailResponse` - contains `program: ProgramDTO`

**Request Types** (from `Models/API/SharedAPITypes.swift`):
- `CreateTemplateRequest`, `UpdateTemplateRequest`, `TemplateExerciseInput`
- `CreateProgramRequest`, `UpdateProgramRequest`, `ProgramWorkoutInput`
- `UpdateUserRequest`
- `SyncRequestDTO`, `SyncResponseDTO`

**Error Type** (from `Models/Errors/RepositoryError.swift`):
```swift
enum RepositoryError: LocalizedError {
    case networkUnavailable
    case serverError(statusCode: Int, message: String?)
    case unauthorized
    case notFound
    case timeout
    case validationError(String)
    case storageError(Error)
    case syncConflict(localId: String, remoteId: String?)
    case rateLimited(retryAfter: TimeInterval?)
    case unknown(Error?)
}
```

**Pagination Types**:
- Protocols return `PaginationInfo` (cursor-based: `nextCursor`, `hasMore`)
- API responses use `PaginationDTO` (page-based: `page`, `perPage`, `total`, `totalPages`)
- You must convert between these formats

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Repository Layer (Agent B)                                 │
│  - Calls API services                                       │
│  - Handles caching                                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  API Service Layer (Agent A) ◄── YOU ARE HERE              │
│  - ExerciseAPIService                                       │
│  - TemplateAPIService                                       │
│  - ProgramAPIService                                        │
│  - SyncAPIService                                           │
│  - UserAPIService                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Network Layer (existing)                                   │
│  - URLSession                                               │
│  - AppConfiguration.shared.baseURL                          │
│  - AuthManager.shared.getIDToken()                          │
└─────────────────────────────────────────────────────────────┘
```

---

## API Endpoints Reference

### Base URL
```swift
AppConfiguration.shared.baseURL  // e.g., https://api.nippardation.com
```

### Authentication
All endpoints except public exercise browsing require Firebase ID token:
```
Authorization: Bearer <firebase_id_token>
```

### Exercises
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/exercises` | List exercises with filters |
| GET | `/api/exercises/:id` | Get single exercise |
| GET | `/api/exercises/filters` | Get filter options with counts |
| POST | `/api/exercises/:id/usage` | Record exercise usage |

**Query Parameters for `/api/exercises`:**
- `page` (int) - Page number (1-based)
- `per_page` (int) - Results per page
- `muscle_groups[]` (string array) - Filter by muscle groups
- `equipment[]` (string array) - Filter by equipment
- `difficulties[]` (string array) - Filter by difficulty
- `movement_patterns[]` (string array) - Filter by movement pattern
- `exercise_types[]` (string array) - Filter by exercise type
- `q` (string) - Search query
- `primary_only` (bool) - Only match primary muscles

### Templates
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/templates` | List user's templates |
| GET | `/api/templates/:id` | Get template with exercises |
| POST | `/api/templates` | Create template |
| PUT | `/api/templates/:id` | Update template metadata |
| PUT | `/api/templates/:id/exercises` | Replace template exercises |
| POST | `/api/templates/:id/clone` | Clone a template |
| DELETE | `/api/templates/:id` | Delete template |

### Programs
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/programs` | List user's programs |
| GET | `/api/programs/:id` | Get program with workouts |
| GET | `/api/programs/active` | Get active program |
| POST | `/api/programs` | Create program |
| PUT | `/api/programs/:id` | Update program metadata |
| PUT | `/api/programs/:id/workouts` | Replace program workouts |
| DELETE | `/api/programs/:id` | Delete program |
| POST | `/api/programs/:id/activate` | Set as active program |
| POST | `/api/programs/:id/deactivate` | Remove active status |
| POST | `/api/programs/:id/advance` | Advance to next day |
| POST | `/api/programs/:id/reset` | Reset progress |

### User/Auth
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/login` | Login/register with Firebase token |
| GET | `/api/users/me` | Get current user profile |
| PUT | `/api/users/me` | Update user profile |

### Sync
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/sync` | Sync workout data |

---

## Implementation Details

### 1. JSONCoders.swift (Create First)

```swift
//
//  JSONCoders.swift
//  Nippardation
//
//  Shared JSON encoder/decoder configured for API communication
//

import Foundation

extension JSONDecoder {
    /// Decoder configured for API responses
    /// Note: DTOs use explicit CodingKeys for snake_case conversion
    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        // Don't use keyDecodingStrategy - DTOs have explicit CodingKeys
        return decoder
    }
}

extension JSONEncoder {
    /// Encoder configured for API requests
    /// Note: Request types use explicit CodingKeys for snake_case conversion
    static var apiEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        // Don't use keyEncodingStrategy - request types have explicit CodingKeys
        return encoder
    }
}
```

### 2. ExerciseFilters Extension

Add this extension to `Models/API/SharedAPITypes.swift` OR create a separate file:

```swift
//
//  ExerciseFilters+QueryItems.swift
//  Nippardation
//
//  Extension for converting ExerciseFilters to URL query items
//

import Foundation

extension ExerciseFilters {
    /// Convert filters to URL query items for API requests
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        for muscle in muscleGroups {
            items.append(URLQueryItem(name: "muscle_groups[]", value: muscle))
        }

        for equip in equipment {
            items.append(URLQueryItem(name: "equipment[]", value: equip))
        }

        for diff in difficulties {
            items.append(URLQueryItem(name: "difficulties[]", value: diff))
        }

        for pattern in movementPatterns {
            items.append(URLQueryItem(name: "movement_patterns[]", value: pattern))
        }

        for type in exerciseTypes {
            items.append(URLQueryItem(name: "exercise_types[]", value: type))
        }

        if !searchQuery.isEmpty {
            items.append(URLQueryItem(name: "q", value: searchQuery))
        }

        if includePrimaryOnly {
            items.append(URLQueryItem(name: "primary_only", value: "true"))
        }

        return items
    }
}
```

### 3. ExerciseAPIService.swift

```swift
//
//  ExerciseAPIService.swift
//  Nippardation
//
//  API service for exercise-related operations
//

import Foundation

final class ExerciseAPIService: ExerciseAPIServiceProtocol, @unchecked Sendable {

    private let session: URLSession
    private let decoder = JSONDecoder.apiDecoder

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - ExerciseAPIServiceProtocol

    func fetchExercises(
        filters: ExerciseFilters?,
        cursor: String?,
        limit: Int
    ) async throws -> (exercises: [ExerciseDTO], pagination: PaginationInfo) {
        var components = URLComponents(
            url: AppConfiguration.shared.baseURL.appendingPathComponent("api/exercises"),
            resolvingAgainstBaseURL: false
        )!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "per_page", value: String(limit))
        ]

        // Convert cursor to page number (cursor is page index as string)
        let page = cursor.flatMap { Int($0) } ?? 1
        queryItems.append(URLQueryItem(name: "page", value: String(page)))

        // Add filter query items
        if let filters = filters {
            queryItems.append(contentsOf: filters.toQueryItems())
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw RepositoryError.unknown(nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: ExerciseListResponse = try await performRequest(request)

        // Convert PaginationDTO to PaginationInfo
        let hasMore = response.pagination.page < response.pagination.totalPages
        let nextCursor = hasMore ? String(response.pagination.page + 1) : nil
        let paginationInfo = PaginationInfo(nextCursor: nextCursor, hasMore: hasMore)

        return (response.exercises, paginationInfo)
    }

    func fetchExercise(id: String) async throws -> ExerciseDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/exercises")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: ExerciseDetailResponse = try await performRequest(request)
        return response.exercise
    }

    func fetchFilterOptions() async throws -> ExerciseFilterOptionsDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/exercises/filters")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        return try await performRequest(request)
    }

    func recordUsage(exerciseId: String) async throws {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/exercises")
            .appendingPathComponent(exerciseId)
            .appendingPathComponent("usage")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try await addAuthHeader(to: &request)

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Private Helpers

    private func addAuthHeader(to request: inout URLRequest) async throws {
        guard let token = try await AuthManager.shared.getIDToken() else {
            throw RepositoryError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw RepositoryError.networkUnavailable
            case .timedOut:
                throw RepositoryError.timeout
            default:
                throw RepositoryError.unknown(error)
            }
        }

        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("Decoding error: \(error)")
            if let json = String(data: data, encoding: .utf8) {
                print("Response: \(json)")
            }
            #endif
            throw RepositoryError.unknown(error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.unknown(nil)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw RepositoryError.unauthorized
        case 404:
            throw RepositoryError.notFound
        case 422:
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Validation failed"
            throw RepositoryError.validationError(message)
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Double($0) }
            throw RepositoryError.rateLimited(retryAfter: retryAfter)
        case 400...499:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        case 500...599:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        default:
            throw RepositoryError.unknown(nil)
        }
    }
}
```

### 4. TemplateAPIService.swift

```swift
//
//  TemplateAPIService.swift
//  Nippardation
//
//  API service for workout template operations
//

import Foundation

final class TemplateAPIService: TemplateAPIServiceProtocol, @unchecked Sendable {

    private let session: URLSession
    private let decoder = JSONDecoder.apiDecoder
    private let encoder = JSONEncoder.apiEncoder

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - TemplateAPIServiceProtocol

    func fetchTemplates(
        cursor: String?,
        limit: Int
    ) async throws -> (templates: [TemplateDTO], pagination: PaginationInfo) {
        var components = URLComponents(
            url: AppConfiguration.shared.baseURL.appendingPathComponent("api/templates"),
            resolvingAgainstBaseURL: false
        )!

        let page = cursor.flatMap { Int($0) } ?? 1
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(limit))
        ]

        guard let url = components.url else {
            throw RepositoryError.unknown(nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: TemplateListResponse = try await performRequest(request)

        let hasMore = response.pagination.page < response.pagination.totalPages
        let nextCursor = hasMore ? String(response.pagination.page + 1) : nil
        let paginationInfo = PaginationInfo(nextCursor: nextCursor, hasMore: hasMore)

        return (response.templates, paginationInfo)
    }

    func fetchTemplate(id: String) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: TemplateDetailResponse = try await performRequest(request)
        return response.template
    }

    func createTemplate(_ createRequest: CreateTemplateRequest) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/templates")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(createRequest)
        try await addAuthHeader(to: &request)

        let response: TemplateDetailResponse = try await performRequest(request)
        return response.template
    }

    func updateTemplate(id: String, _ updateRequest: UpdateTemplateRequest) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(updateRequest)
        try await addAuthHeader(to: &request)

        let response: TemplateDetailResponse = try await performRequest(request)
        return response.template
    }

    func updateTemplateExercises(
        id: String,
        _ exercises: [TemplateExerciseInput]
    ) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)
            .appendingPathComponent("exercises")

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(["exercises": exercises])
        try await addAuthHeader(to: &request)

        let response: TemplateDetailResponse = try await performRequest(request)
        return response.template
    }

    func cloneTemplate(id: String, newName: String?) async throws -> TemplateDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)
            .appendingPathComponent("clone")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let name = newName {
            request.httpBody = try encoder.encode(["name": name])
        }
        try await addAuthHeader(to: &request)

        let response: TemplateDetailResponse = try await performRequest(request)
        return response.template
    }

    func deleteTemplate(id: String) async throws {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/templates")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await addAuthHeader(to: &request)

        let (data, response) = try await session.data(for: request)

        // Check for 409 Conflict (template in use by program)
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 409 {
            let message = String(data: data, encoding: .utf8) ?? "Template is in use"
            throw RepositoryError.syncConflict(localId: id, remoteId: nil)
        }

        try validateResponse(response, data: data)
    }

    // MARK: - Private Helpers

    private func addAuthHeader(to request: inout URLRequest) async throws {
        guard let token = try await AuthManager.shared.getIDToken() else {
            throw RepositoryError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw RepositoryError.networkUnavailable
            case .timedOut:
                throw RepositoryError.timeout
            default:
                throw RepositoryError.unknown(error)
            }
        }

        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("Decoding error: \(error)")
            if let json = String(data: data, encoding: .utf8) {
                print("Response: \(json)")
            }
            #endif
            throw RepositoryError.unknown(error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.unknown(nil)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw RepositoryError.unauthorized
        case 404:
            throw RepositoryError.notFound
        case 422:
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Validation failed"
            throw RepositoryError.validationError(message)
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Double($0) }
            throw RepositoryError.rateLimited(retryAfter: retryAfter)
        case 400...499:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        case 500...599:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        default:
            throw RepositoryError.unknown(nil)
        }
    }
}
```

### 5. ProgramAPIService.swift

```swift
//
//  ProgramAPIService.swift
//  Nippardation
//
//  API service for workout program operations
//

import Foundation

final class ProgramAPIService: ProgramAPIServiceProtocol, @unchecked Sendable {

    private let session: URLSession
    private let decoder = JSONDecoder.apiDecoder
    private let encoder = JSONEncoder.apiEncoder

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - CRUD Operations

    func fetchPrograms(
        cursor: String?,
        limit: Int
    ) async throws -> (programs: [ProgramDTO], pagination: PaginationInfo) {
        var components = URLComponents(
            url: AppConfiguration.shared.baseURL.appendingPathComponent("api/programs"),
            resolvingAgainstBaseURL: false
        )!

        let page = cursor.flatMap { Int($0) } ?? 1
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(limit))
        ]

        guard let url = components.url else {
            throw RepositoryError.unknown(nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: ProgramListResponse = try await performRequest(request)

        let hasMore = response.pagination.page < response.pagination.totalPages
        let nextCursor = hasMore ? String(response.pagination.page + 1) : nil
        let paginationInfo = PaginationInfo(nextCursor: nextCursor, hasMore: hasMore)

        return (response.programs, paginationInfo)
    }

    func fetchProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func fetchActiveProgram() async throws -> ActiveProgramDTO? {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs/active")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        do {
            return try await performRequest(request)
        } catch RepositoryError.notFound {
            // No active program is a valid state
            return nil
        }
    }

    func createProgram(_ createRequest: CreateProgramRequest) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/programs")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(createRequest)
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func updateProgram(id: String, _ updateRequest: UpdateProgramRequest) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(updateRequest)
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func updateProgramWorkouts(
        id: String,
        _ workouts: [ProgramWorkoutInput]
    ) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("workouts")

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(["workouts": workouts])
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func deleteProgram(id: String) async throws {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await addAuthHeader(to: &request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - State Management

    func activateProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("activate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func deactivateProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("deactivate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func advanceProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("advance")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    func resetProgram(id: String) async throws -> ProgramDTO {
        let url = AppConfiguration.shared.baseURL
            .appendingPathComponent("api/programs")
            .appendingPathComponent(id)
            .appendingPathComponent("reset")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let response: ProgramDetailResponse = try await performRequest(request)
        return response.program
    }

    // MARK: - Private Helpers

    private func addAuthHeader(to request: inout URLRequest) async throws {
        guard let token = try await AuthManager.shared.getIDToken() else {
            throw RepositoryError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw RepositoryError.networkUnavailable
            case .timedOut:
                throw RepositoryError.timeout
            default:
                throw RepositoryError.unknown(error)
            }
        }

        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("Decoding error: \(error)")
            if let json = String(data: data, encoding: .utf8) {
                print("Response: \(json)")
            }
            #endif
            throw RepositoryError.unknown(error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.unknown(nil)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw RepositoryError.unauthorized
        case 404:
            throw RepositoryError.notFound
        case 422:
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Validation failed"
            throw RepositoryError.validationError(message)
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Double($0) }
            throw RepositoryError.rateLimited(retryAfter: retryAfter)
        case 400...499:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        case 500...599:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        default:
            throw RepositoryError.unknown(nil)
        }
    }
}
```

### 6. SyncAPIService.swift

```swift
//
//  SyncAPIService.swift
//  Nippardation
//
//  API service for data synchronization
//

import Foundation

final class SyncAPIService: SyncAPIServiceProtocol, @unchecked Sendable {

    private let session: URLSession
    private let decoder = JSONDecoder.apiDecoder
    private let encoder = JSONEncoder.apiEncoder

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - SyncAPIServiceProtocol

    func sync(payload: SyncRequestDTO) async throws -> SyncResponseDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/sync")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(payload)
        try await addAuthHeader(to: &request)

        // Sync operations may take longer
        request.timeoutInterval = 60

        return try await performRequest(request)
    }

    // MARK: - Private Helpers

    private func addAuthHeader(to request: inout URLRequest) async throws {
        guard let token = try await AuthManager.shared.getIDToken() else {
            throw RepositoryError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw RepositoryError.networkUnavailable
            case .timedOut:
                throw RepositoryError.timeout
            default:
                throw RepositoryError.unknown(error)
            }
        }

        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("Decoding error: \(error)")
            if let json = String(data: data, encoding: .utf8) {
                print("Response: \(json)")
            }
            #endif
            throw RepositoryError.unknown(error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.unknown(nil)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw RepositoryError.unauthorized
        case 404:
            throw RepositoryError.notFound
        case 409:
            // Sync conflict - let caller handle via response data
            return
        case 422:
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Validation failed"
            throw RepositoryError.validationError(message)
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Double($0) }
            throw RepositoryError.rateLimited(retryAfter: retryAfter)
        case 400...499:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        case 500...599:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        default:
            throw RepositoryError.unknown(nil)
        }
    }
}
```

### 7. UserAPIService.swift

```swift
//
//  UserAPIService.swift
//  Nippardation
//
//  API service for user/auth operations
//

import Foundation

/// Response wrapper for user endpoints
private struct UserResponse: Codable {
    let success: Bool
    let user: UserDTO
}

final class UserAPIService: UserAPIServiceProtocol, @unchecked Sendable {

    private let session: URLSession
    private let decoder = JSONDecoder.apiDecoder
    private let encoder = JSONEncoder.apiEncoder

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - UserAPIServiceProtocol

    func login() async throws -> UserDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/auth/login")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let response: UserResponse = try await performRequest(request)
        return response.user
    }

    func fetchProfile() async throws -> UserDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/users/me")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let response: UserResponse = try await performRequest(request)
        return response.user
    }

    func updateProfile(_ updateRequest: UpdateUserRequest) async throws -> UserDTO {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent("api/users/me")

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try encoder.encode(updateRequest)
        try await addAuthHeader(to: &request)

        let response: UserResponse = try await performRequest(request)
        return response.user
    }

    // MARK: - Private Helpers

    private func addAuthHeader(to request: inout URLRequest) async throws {
        guard let token = try await AuthManager.shared.getIDToken() else {
            throw RepositoryError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw RepositoryError.networkUnavailable
            case .timedOut:
                throw RepositoryError.timeout
            default:
                throw RepositoryError.unknown(error)
            }
        }

        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("Decoding error: \(error)")
            if let json = String(data: data, encoding: .utf8) {
                print("Response: \(json)")
            }
            #endif
            throw RepositoryError.unknown(error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.unknown(nil)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw RepositoryError.unauthorized
        case 404:
            throw RepositoryError.notFound
        case 422:
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Validation failed"
            throw RepositoryError.validationError(message)
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Double($0) }
            throw RepositoryError.rateLimited(retryAfter: retryAfter)
        case 400...499:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        case 500...599:
            let message = data.flatMap { String(data: $0, encoding: .utf8) }
            throw RepositoryError.serverError(statusCode: httpResponse.statusCode, message: message)
        default:
            throw RepositoryError.unknown(nil)
        }
    }
}
```

---

## File Structure After Implementation

```
Nippardation/
├── Services/
│   ├── API/
│   │   ├── ExerciseAPIService.swift      ◄ NEW
│   │   ├── TemplateAPIService.swift      ◄ NEW
│   │   ├── ProgramAPIService.swift       ◄ NEW
│   │   ├── SyncAPIService.swift          ◄ NEW
│   │   └── UserAPIService.swift          ◄ NEW
│   ├── Utilities/
│   │   ├── JSONCoders.swift              ◄ NEW
│   │   └── NetworkMonitor.swift          (existing)
│   ├── Protocols/                         (DO NOT MODIFY)
│   │   ├── ExerciseAPIServiceProtocol.swift
│   │   ├── TemplateAPIServiceProtocol.swift
│   │   ├── ProgramAPIServiceProtocol.swift
│   │   ├── SyncAPIServiceProtocol.swift
│   │   └── UserAPIServiceProtocol.swift
│   └── Mocks/                             (existing)
├── Models/
│   └── API/
│       └── ExerciseFilters+QueryItems.swift  ◄ NEW (or add to SharedAPITypes.swift)
```

---

## Integration with DependencyContainer

After creating the services, they should be registered in `DependencyContainer.configureForProduction()`:

```swift
func configureForProduction() {
    self.exerciseAPIService = ExerciseAPIService()
    self.templateAPIService = TemplateAPIService()
    self.programAPIService = ProgramAPIService()
    self.syncAPIService = SyncAPIService()
    self.userAPIService = UserAPIService()
}
```

**Note:** Do not modify `DependencyContainer.swift` yourself - that will be done during integration.

---

## Verification Checklist

Before marking complete:

- [ ] All 5 service files created in `Services/API/`
- [ ] `JSONCoders.swift` created in `Services/Utilities/`
- [ ] `ExerciseFilters+QueryItems.swift` created (or extension added)
- [ ] Each service conforms to its protocol exactly
- [ ] All error handling uses existing `RepositoryError` cases
- [ ] URL building uses `appendingPathComponent` consistently
- [ ] Auth tokens attached via `AuthManager.shared.getIDToken()`
- [ ] Pagination conversion from `PaginationDTO` to `PaginationInfo` works correctly
- [ ] Build succeeds:
  ```bash
  xcodebuild -project Nippardation.xcodeproj -scheme Nippardation -sdk iphonesimulator build
  ```

---

## Key Differences from Original Prompt

This corrected version addresses the following issues from the original prompt:

1. **Uses existing response types** (`ExerciseListResponse`, `TemplateDetailResponse`, etc.) instead of invented wrapper types
2. **Uses existing `RepositoryError` cases** - no `.networkError`, `.decodingError`, or `.conflict` (which don't exist)
3. **Handles pagination conversion** - protocols expect `PaginationInfo` (cursor-based), DTOs provide `PaginationDTO` (page-based)
4. **Adds missing `toQueryItems()` extension** as a deliverable
5. **Consistent URL building** using `appendingPathComponent` throughout
6. **Simplified architecture** - removed unused `NetworkManager` dependency
7. **Private response wrappers** where needed (`UserResponse` in UserAPIService)

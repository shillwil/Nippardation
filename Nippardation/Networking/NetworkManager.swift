//
//  NetworkManager.swift
//  Nippardation
//
//  Created by Claude on 7/10/25.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(String)
    case unknown(Error)
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        
        // Configure decoder/encoder
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Base Request Method
    
    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type
    ) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError(domain: "Invalid response", code: 0))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw NetworkError.decodingError
                }
            case 401:
                throw NetworkError.unauthorized
            case 400...499:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Client error"
                throw NetworkError.serverError(errorMessage)
            case 500...599:
                throw NetworkError.serverError("Server error: \(httpResponse.statusCode)")
            default:
                throw NetworkError.unknown(NSError(domain: "HTTP Error", code: httpResponse.statusCode))
            }
        } catch {
            if error is NetworkError {
                throw error
            }
            throw NetworkError.unknown(error)
        }
    }
    
    // MARK: - Authenticated Request Builder
    
    private func buildAuthenticatedRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> URLRequest {
        let url = AppConfiguration.shared.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Firebase auth token
        if let idToken = try await AuthManager.shared.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Add environment header for debugging
        request.setValue(AppConfiguration.shared.environment.rawValue, forHTTPHeaderField: "X-Environment")
        
        request.httpBody = body
        
        return request
    }
    
    // MARK: - Public API Methods
    
    func get<T: Decodable>(
        path: String,
        responseType: T.Type
    ) async throws -> T {
        let request = try await buildAuthenticatedRequest(path: path)
        return try await performRequest(request, responseType: responseType)
    }
    
    func post<T: Encodable, U: Decodable>(
        path: String,
        body: T,
        responseType: U.Type
    ) async throws -> U {
        let bodyData = try encoder.encode(body)
        let request = try await buildAuthenticatedRequest(path: path, method: "POST", body: bodyData)
        return try await performRequest(request, responseType: responseType)
    }
    
    func put<T: Encodable, U: Decodable>(
        path: String,
        body: T,
        responseType: U.Type
    ) async throws -> U {
        let bodyData = try encoder.encode(body)
        let request = try await buildAuthenticatedRequest(path: path, method: "PUT", body: bodyData)
        return try await performRequest(request, responseType: responseType)
    }
    
    func delete(path: String) async throws {
        let request = try await buildAuthenticatedRequest(path: path, method: "DELETE")
        _ = try await session.data(for: request)
    }
}

// MARK: - Example Usage for Backend Integration

extension NetworkManager {
    // Example: Sync workout data with backend
    func syncWorkout(_ workout: TrackedWorkout) async throws {
        struct WorkoutResponse: Decodable {
            let id: String
            let success: Bool
        }
        
        _ = try await post(
            path: "/workouts",
            body: workout,
            responseType: WorkoutResponse.self
        )
    }
    
    // Example: Fetch user's workout history from backend
    func fetchWorkoutHistory() async throws -> [TrackedWorkout] {
        struct WorkoutHistoryResponse: Decodable {
            let workouts: [TrackedWorkout]
        }
        
        let response = try await get(
            path: "/workouts",
            responseType: WorkoutHistoryResponse.self
        )
        
        return response.workouts
    }
}
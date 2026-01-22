//
//  JSONCodersTests.swift
//  NippardationTests
//
//  Tests for JSONCoders extensions
//

import Testing
import Foundation
@testable import Nippardation

struct JSONCodersTests {

    // MARK: - Test Types

    private struct TestModel: Codable, Equatable {
        let id: String
        let userName: String
        let createdAt: String

        enum CodingKeys: String, CodingKey {
            case id
            case userName = "user_name"
            case createdAt = "created_at"
        }
    }

    // MARK: - Decoder Tests

    @Test func apiDecoderDecodesSnakeCaseWithCodingKeys() throws {
        let json = """
        {
            "id": "123",
            "user_name": "testuser",
            "created_at": "2025-01-01"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder.apiDecoder.decode(TestModel.self, from: json)

        #expect(decoded.id == "123")
        #expect(decoded.userName == "testuser")
        #expect(decoded.createdAt == "2025-01-01")
    }

    @Test func apiDecoderReturnsNewInstanceEachTime() {
        let decoder1 = JSONDecoder.apiDecoder
        let decoder2 = JSONDecoder.apiDecoder

        // They should be different instances
        #expect(decoder1 !== decoder2)
    }

    // MARK: - Encoder Tests

    @Test func apiEncoderEncodesWithCodingKeys() throws {
        let model = TestModel(id: "456", userName: "anotheruser", createdAt: "2025-06-15")

        let data = try JSONEncoder.apiEncoder.encode(model)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("\"id\":\"456\""))
        #expect(jsonString.contains("\"user_name\":\"anotheruser\""))
        #expect(jsonString.contains("\"created_at\":\"2025-06-15\""))
    }

    @Test func apiEncoderReturnsNewInstanceEachTime() {
        let encoder1 = JSONEncoder.apiEncoder
        let encoder2 = JSONEncoder.apiEncoder

        // They should be different instances
        #expect(encoder1 !== encoder2)
    }

    // MARK: - Round Trip Tests

    @Test func roundTripEncodingDecodingPreservesData() throws {
        let original = TestModel(id: "789", userName: "roundtrip", createdAt: "2025-12-31")

        let encoded = try JSONEncoder.apiEncoder.encode(original)
        let decoded = try JSONDecoder.apiDecoder.decode(TestModel.self, from: encoded)

        #expect(decoded == original)
    }

    // MARK: - DTO Compatibility Tests

    @Test func decoderWorksWithExerciseDTO() throws {
        let json = """
        {
            "id": "ex_001",
            "name": "Bench Press",
            "primary_muscles": ["chest"],
            "secondary_muscles": ["triceps"],
            "equipment": "barbell",
            "difficulty": "intermediate"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder.apiDecoder.decode(ExerciseDTO.self, from: json)

        #expect(decoded.id == "ex_001")
        #expect(decoded.name == "Bench Press")
        #expect(decoded.primaryMuscles == ["chest"])
        #expect(decoded.secondaryMuscles == ["triceps"])
        #expect(decoded.equipment == "barbell")
        #expect(decoded.difficulty == "intermediate")
    }

    @Test func decoderWorksWithPaginationDTO() throws {
        let json = """
        {
            "page": 1,
            "per_page": 20,
            "total": 100,
            "total_pages": 5
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder.apiDecoder.decode(PaginationDTO.self, from: json)

        #expect(decoded.page == 1)
        #expect(decoded.perPage == 20)
        #expect(decoded.total == 100)
        #expect(decoded.totalPages == 5)
    }

    @Test func decoderWorksWithPaginationInfo() throws {
        let json = """
        {
            "next_cursor": "page_2",
            "has_more": true
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder.apiDecoder.decode(PaginationInfo.self, from: json)

        #expect(decoded.nextCursor == "page_2")
        #expect(decoded.hasMore == true)
    }
}

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

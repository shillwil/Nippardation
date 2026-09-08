//
//  UserScopedDefaults.swift
//  Nippardation
//
//  Small JSON-in-UserDefaults helper keyed per signed-in user, so local state
//  (received plans, today's override, body weight) never bleeds between accounts.
//

import Foundation

struct UserScopedDefaults {
    let namespace: String
    let defaults: UserDefaults
    let userIdProvider: () -> String?

    init(namespace: String, defaults: UserDefaults = .standard, userIdProvider: @escaping () -> String?) {
        self.namespace = namespace
        self.defaults = defaults
        self.userIdProvider = userIdProvider
    }

    var key: String {
        "void.\(namespace).\(userIdProvider() ?? "anonymous")"
    }

    func load<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder.voidStore.decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T) {
        if let data = try? JSONEncoder.voidStore.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

extension JSONEncoder {
    static let voidStore: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let voidStore: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

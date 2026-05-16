import Foundation

struct KeyValueStorageKey<T>: ExpressibleByStringLiteral {
    let name: String

    init(stringLiteral value: StaticString) {
        self.init(name: "\(value)")
    }

    init(name: String) {
        self.name = name
    }
}

protocol KeyValueStorageType: Sendable {
    subscript<T: Codable & Sendable>(_ key: KeyValueStorageKey<T>) -> T? { get nonmutating set }
}

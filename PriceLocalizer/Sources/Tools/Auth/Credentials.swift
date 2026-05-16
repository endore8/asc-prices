import Foundation

struct Credentials: Codable, Sendable, Equatable {
    let keyId: String
    let issuerId: String
    let privateKeyPEM: String
}

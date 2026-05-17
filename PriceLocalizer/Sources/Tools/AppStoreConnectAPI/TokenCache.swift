import CryptoKit
import Foundation

actor TokenCache {
    enum TokenError: Error {
        case invalidPEM
        case encoding
    }

    private static let ttl: TimeInterval = 20 * 60
    private static let refreshBuffer: TimeInterval = 60

    private let credentials: Credentials
    private var cached: (token: String, expiresAt: Date)?

    init(credentials: Credentials) {
        self.credentials = credentials
    }

    func token() throws -> String {
        if let cached = self.cached, cached.expiresAt.timeIntervalSinceNow > Self.refreshBuffer {
            return cached.token
        }
        let minted = try self.issueToken()
        self.cached = minted
        return minted.token
    }

    // MARK: - Private

    private func issueToken() throws -> (token: String, expiresAt: Date) {
        let issuedAt = Date()
        let expiresAt = issuedAt.addingTimeInterval(Self.ttl)
        let header: [String: String] = [
            "alg": "ES256",
            "kid": self.credentials.keyId,
            "typ": "JWT",
        ]
        let payload: [String: Any] = [
            "iss": self.credentials.issuerId,
            "iat": Int(issuedAt.timeIntervalSince1970),
            "exp": Int(expiresAt.timeIntervalSince1970),
            "aud": "appstoreconnect-v1",
        ]

        let headerData = try JSONSerialization.data(withJSONObject: header, options: [.sortedKeys])
        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])

        let signingInput = "\(headerData.base64URLEncodedString()).\(payloadData.base64URLEncodedString())"
        guard let signingData = signingInput.data(using: .utf8) else {
            throw TokenError.encoding
        }

        let key = try P256.Signing.PrivateKey(pemRepresentation: self.credentials.privateKeyPEM)
        let signature = try key.signature(for: signingData)
        let token = "\(signingInput).\(signature.rawRepresentation.base64URLEncodedString())"
        return (token: token, expiresAt: expiresAt)
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

import CryptoKit
import Foundation

enum JWTSigner {
    enum JWTError: Error {
        case invalidPEM
        case encoding
    }

    static func sign(credentials: Credentials, ttl: TimeInterval = 19 * 60) throws -> String {
        let now = Int(Date().timeIntervalSince1970)
        let header: [String: String] = ["alg": "ES256", "kid": credentials.keyId, "typ": "JWT"]
        let payload: [String: Any] = [
            "iss": credentials.issuerId,
            "iat": now,
            "exp": now + Int(ttl),
            "aud": "appstoreconnect-v1",
        ]

        let headerData = try JSONSerialization.data(withJSONObject: header, options: [.sortedKeys])
        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])

        let signingInput = "\(headerData.base64URLEncodedString()).\(payloadData.base64URLEncodedString())"
        guard let signingData = signingInput.data(using: .utf8) else {
            throw JWTError.encoding
        }

        let key = try P256.Signing.PrivateKey(pemRepresentation: credentials.privateKeyPEM)
        let signature = try key.signature(for: signingData)
        let sigBase64 = signature.rawRepresentation.base64URLEncodedString()
        return "\(signingInput).\(sigBase64)"
    }
}

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

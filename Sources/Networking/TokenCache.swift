import Foundation

actor TokenCache {
    private let credentials: Credentials
    private var cached: String?
    private var expiresAt: Date = .distantPast

    init(credentials: Credentials) {
        self.credentials = credentials
    }

    func token() throws -> String {
        if let cached, expiresAt.timeIntervalSinceNow > 60 {
            return cached
        }
        let signed = try JWTSigner.sign(credentials: credentials)
        self.cached = signed
        self.expiresAt = Date().addingTimeInterval(19 * 60)
        return signed
    }
}

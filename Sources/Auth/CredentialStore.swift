import Foundation

enum CredentialStore {
    static let account = "default"

    static func load() -> Credentials? {
        guard let data = Keychain.getData(account: account) else { return nil }
        return try? JSONDecoder().decode(Credentials.self, from: data)
    }

    static func save(_ credentials: Credentials) throws {
        let data = try JSONEncoder().encode(credentials)
        try Keychain.setData(data, account: account)
    }

    static func clear() {
        Keychain.delete(account: account)
    }
}

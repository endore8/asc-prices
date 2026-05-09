import Foundation
import Observation

@MainActor
@Observable
final class AppSession {
    var credentials: Credentials? = CredentialStore.load()
    var baseCountry: String =
        UserDefaults.standard.string(forKey: "baseCountry") ?? "USA"

    func setCredentials(_ creds: Credentials) throws {
        try CredentialStore.save(creds)
        credentials = creds
    }

    func clearCredentials() {
        CredentialStore.clear()
        credentials = nil
    }

    func setBaseCountry(_ code: String) {
        baseCountry = code
        UserDefaults.standard.set(code, forKey: "baseCountry")
    }
}

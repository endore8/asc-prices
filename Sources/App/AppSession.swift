import Foundation
import Observation

@MainActor
@Observable
final class AppSession {
    var credentials: Credentials? = CredentialStore.load()

    func setCredentials(_ creds: Credentials) throws {
        try CredentialStore.save(creds)
        credentials = creds
    }

    func clearCredentials() {
        CredentialStore.clear()
        credentials = nil
    }
}

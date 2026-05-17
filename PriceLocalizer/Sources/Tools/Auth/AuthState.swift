import Foundation
import Observation

@MainActor
@Observable
final class AuthState {
    private let storage: KeyValueStorageType

    private(set) var credentials: Credentials?

    init(storage: KeyValueStorageType) {
        self.storage = storage
        self.credentials = self.storage[AppConstants.StorageKeys.credentials]
    }

    func setCredentials(_ credentials: Credentials) {
        self.storage[AppConstants.StorageKeys.credentials] = credentials
        self.credentials = credentials
    }

    func clearCredentials() {
        self.storage[AppConstants.StorageKeys.credentials] = nil
        self.credentials = nil
    }
}

import Foundation

struct AppDependencies {
    let authState: AuthState

    @MainActor
    init() {
        let storage = Keychain(service: AppConstants.keychainService)
        self.authState = AuthState(storage: storage)
    }
}

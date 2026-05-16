import Foundation

struct AppDependencies {
    let persistentKeyValueStorage: KeyValueStorageType

    init() {
        self.persistentKeyValueStorage = Keychain(service: AppConstants.keychainService)
    }
}

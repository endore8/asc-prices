import Foundation

enum AppConstants {
    static let keychainService = "com.endore8.price-localizer"

    enum StorageKeys {
        static let credentials: KeyValueStorageKey<Credentials> = "auth.credentials"
    }
}

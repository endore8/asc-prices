import Foundation
import Security

struct Keychain: KeyValueStorageType {
    let service: String

    // MARK: - KeyValueStorageType

    subscript<T: Codable & Sendable>(_ key: KeyValueStorageKey<T>) -> T? {
        get {
            self.read(account: key.name).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
        }
        nonmutating set {
            if let data = newValue.flatMap({ try? JSONEncoder().encode($0) }) {
                self.write(data, account: key.name)
            }
            else {
                self.delete(account: key.name)
            }
        }
    }

    // MARK: - Private

    private func read(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }

    private func write(_ data: Data, account: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true,
        ]
        SecItemDelete(base as CFDictionary)

        var attrs = base
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        _ = SecItemAdd(attrs as CFDictionary, nil)
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

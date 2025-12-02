import Security
import Foundation

class KeychainHelper {
    static let shared = KeychainHelper()

    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ] as [String : Any]

        SecItemDelete(query as CFDictionary)  // Delete old value if exists
        SecItemAdd(query as CFDictionary, nil)
    }

    func retrieve(service: String, account: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String : Any]

        var data: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &data)
        return status == errSecSuccess ? (data as? Data) : nil
    }

    func delete(service: String, account: String) {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ] as [String : Any]

        SecItemDelete(query as CFDictionary)
    }
}

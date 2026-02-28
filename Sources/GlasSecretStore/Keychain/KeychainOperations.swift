//
//  KeychainOperations.swift
//  GlasSecretStore
//
//  Low-level SecItem* CRUD with access group injection.
//  All operations use the configuration's access group and accessibility level.
//

import Foundation
import Security

public enum KeychainOperations: Sendable {

    // MARK: - Password (String) Operations

    public static func savePassword(
        _ value: String,
        account: String,
        service: String,
        config: SecretStoreConfiguration
    ) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecretStoreError.encodingFailed
        }
        try saveData(data, account: account, service: service, config: config)
    }

    public static func retrievePassword(
        account: String,
        service: String,
        config: SecretStoreConfiguration
    ) throws -> String {
        let data = try retrieveData(account: account, service: service, config: config)
        guard let value = String(data: data, encoding: .utf8) else {
            throw SecretStoreError.notFound
        }
        return value
    }

    /// Tries the primary service name, then each legacy prefix in order.
    public static func retrievePasswordWithFallback(
        account: String,
        primaryService: String,
        legacySuffix: String,
        config: SecretStoreConfiguration
    ) throws -> String {
        // Try primary first
        if let value = try? retrievePassword(account: account, service: primaryService, config: config) {
            return value
        }
        // Try each legacy prefix
        for prefix in config.legacyServiceNamePrefixes {
            let legacyService = "\(prefix).\(legacySuffix)"
            if let value = try? retrievePassword(account: account, service: legacyService, config: config) {
                return value
            }
        }
        throw SecretStoreError.notFound
    }

    public static func deletePassword(
        account: String,
        service: String,
        config: SecretStoreConfiguration
    ) throws {
        try deleteItem(account: account, service: service, config: config)
    }

    // MARK: - Data Operations

    public static func saveData(
        _ data: Data,
        account: String,
        service: String,
        config: SecretStoreConfiguration
    ) throws {
        // Delete any existing entry first
        let deleteQuery = baseQuery(account: account, service: service, config: config)
        SecItemDelete(deleteQuery as CFDictionary)

        var addQuery = baseQuery(account: account, service: service, config: config)
        addQuery[kSecAttrAccessible as String] = config.accessibility
        addQuery[kSecAttrComment as String] = config.migrationMarkerComment
        addQuery[kSecValueData as String] = data

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecretStoreError.unableToSave
        }
    }

    public static func retrieveData(
        account: String,
        service: String,
        config: SecretStoreConfiguration
    ) throws -> Data {
        var query = baseQuery(account: account, service: service, config: config)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw SecretStoreError.notFound
        }
        return data
    }

    public static func deleteItem(
        account: String,
        service: String,
        config: SecretStoreConfiguration
    ) throws {
        let query = baseQuery(account: account, service: service, config: config)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecretStoreError.unableToDelete
        }
    }

    // MARK: - Query Building

    private static func baseQuery(
        account: String,
        service: String,
        config: SecretStoreConfiguration
    ) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        if let accessGroup = config.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }

    // MARK: - Bulk Query (for migration)

    public static func allItems(
        service: String,
        config: SecretStoreConfiguration
    ) -> [[String: Any]] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        if let accessGroup = config.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            return []
        }
        return items
    }

    public static func updateItem(
        account: String,
        service: String,
        data: Data,
        config: SecretStoreConfiguration
    ) -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        if let accessGroup = config.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let updateValues: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: config.accessibility,
            kSecAttrComment as String: config.migrationMarkerComment
        ]
        let status = SecItemUpdate(query as CFDictionary, updateValues as CFDictionary)
        return status == errSecSuccess
    }

    public static func itemCount(
        service: String,
        legacyOnly: Bool,
        config: SecretStoreConfiguration
    ) -> Int {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]
        if let accessGroup = config.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            return 0
        }
        if !legacyOnly { return items.count }
        return items.filter { item in
            let comment = item[kSecAttrComment as String] as? String
            return comment != config.migrationMarkerComment
        }.count
    }
}

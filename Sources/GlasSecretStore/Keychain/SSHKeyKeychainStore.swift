//
//  SSHKeyKeychainStore.swift
//  GlasSecretStore
//
//  Save/retrieve/delete SSH keys by UUID.
//  Supports plain keys (imported/legacy) and Secure Enclave P256.
//

import Foundation

public enum SSHKeyKeychainStore: Sendable {

    // MARK: - Save

    public static func save(
        privateKey: String,
        passphrase: String?,
        for keyID: UUID,
        config: SecretStoreConfiguration
    ) throws {
        try KeychainOperations.savePassword(
            privateKey,
            account: keyID.uuidString,
            service: config.sshKeysPrivateService,
            config: config
        )
        if let passphrase, !passphrase.isEmpty {
            try KeychainOperations.savePassword(
                passphrase,
                account: keyID.uuidString,
                service: config.sshKeysPassphraseService,
                config: config
            )
        } else {
            // Clear any stale passphrase
            try? KeychainOperations.deleteItem(
                account: keyID.uuidString,
                service: config.sshKeysPassphraseService,
                config: config
            )
        }
    }

    // MARK: - Retrieve

    public static func retrieve(
        for keyID: UUID,
        config: SecretStoreConfiguration
    ) throws -> SSHKeyMaterial {
        // Try plain key first
        if let privateKey = try? KeychainOperations.retrievePassword(
            account: keyID.uuidString,
            service: config.sshKeysPrivateService,
            config: config
        ) {
            let passphrase = try? KeychainOperations.retrievePassword(
                account: keyID.uuidString,
                service: config.sshKeysPassphraseService,
                config: config
            )
            return SSHKeyMaterial(privateKey: privateKey, passphrase: passphrase)
        }

        // Try Secure Enclave wrapped P256
        if let (wrapped, keyTag) = try? retrieveSecureEnclaveWrapped(for: keyID, config: config) {
            let raw = try SecureEnclaveKeyManager.unwrap(wrapped: wrapped, keyTag: keyTag)
            let marker = "SECURE_ENCLAVE_P256:\(raw.base64EncodedString())"
            return SSHKeyMaterial(privateKey: marker, passphrase: nil)
        }

        throw SecretStoreError.notFound
    }

    // MARK: - Delete

    public static func delete(
        for keyID: UUID,
        config: SecretStoreConfiguration
    ) throws {
        try KeychainOperations.deleteItem(
            account: keyID.uuidString,
            service: config.sshKeysPrivateService,
            config: config
        )
        try? KeychainOperations.deleteItem(
            account: keyID.uuidString,
            service: config.sshKeysPassphraseService,
            config: config
        )
        // Clean up Secure Enclave artifacts
        if let keyTag = try? KeychainOperations.retrievePassword(
            account: keyID.uuidString,
            service: config.sealedP256TagService,
            config: config
        ) {
            SecureEnclaveKeyManager.deleteKeyIfPresent(keyTag: keyTag)
        }
        try? KeychainOperations.deleteItem(
            account: keyID.uuidString,
            service: config.sealedP256Service,
            config: config
        )
        try? KeychainOperations.deleteItem(
            account: keyID.uuidString,
            service: config.sealedP256TagService,
            config: config
        )
    }

    // MARK: - Secure Enclave Wrapped P256

    public static func saveSecureEnclaveWrapped(
        _ wrapped: Data,
        keyTag: String,
        for keyID: UUID,
        config: SecretStoreConfiguration
    ) throws {
        try KeychainOperations.saveData(
            wrapped,
            account: keyID.uuidString,
            service: config.sealedP256Service,
            config: config
        )
        try KeychainOperations.savePassword(
            keyTag,
            account: keyID.uuidString,
            service: config.sealedP256TagService,
            config: config
        )
    }

    public static func retrieveSecureEnclaveWrapped(
        for keyID: UUID,
        config: SecretStoreConfiguration
    ) throws -> (wrapped: Data, keyTag: String) {
        let wrapped = try KeychainOperations.retrieveData(
            account: keyID.uuidString,
            service: config.sealedP256Service,
            config: config
        )
        let keyTag = try KeychainOperations.retrievePassword(
            account: keyID.uuidString,
            service: config.sealedP256TagService,
            config: config
        )
        return (wrapped, keyTag)
    }
}

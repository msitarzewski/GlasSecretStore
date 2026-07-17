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
        privateKey: SecureBytes,
        passphrase: SecureBytes?,
        for keyID: UUID,
        config: SecretStoreConfiguration
    ) throws {
        let bundle = StoredSSHKeyBundle(
            privateKey: privateKey.toData(),
            passphrase: passphrase.flatMap { $0.count > 0 ? $0.toData() : nil }
        )
        try KeychainOperations.saveData(
            try JSONEncoder().encode(bundle),
            account: keyID.uuidString,
            service: config.sshKeysPrivateService,
            config: config
        )
    }

    // MARK: - Retrieve

    public static func retrieve(
        for keyID: UUID,
        config: SecretStoreConfiguration
    ) throws -> SSHKeyMaterial {
        // Try plain key first (retrieve as Data to avoid intermediate String)
        do {
            let privateKeyData = try KeychainOperations.retrieveData(
                account: keyID.uuidString,
                service: config.sshKeysPrivateService,
                config: config
            )
            if let bundle = try? JSONDecoder().decode(StoredSSHKeyBundle.self, from: privateKeyData) {
                return SSHKeyMaterial(
                    privateKey: SecureBytes(bundle.privateKey),
                    passphrase: bundle.passphrase.map(SecureBytes.init)
                )
            }
            let passphraseData: Data?
            do {
                passphraseData = try KeychainOperations.retrieveData(
                    account: keyID.uuidString,
                    service: config.sshKeysPassphraseService,
                    config: config
                )
            } catch SecretStoreError.notFound {
                passphraseData = nil
            }
            return SSHKeyMaterial(
                privateKey: SecureBytes(privateKeyData),
                passphrase: passphraseData.map { SecureBytes($0) }
            )
        } catch SecretStoreError.notFound {
            // Try the Secure Enclave representation below.
        }

        // Try Secure Enclave wrapped P256
        do {
            let (wrapped, keyTag) = try retrieveSecureEnclaveWrapped(for: keyID, config: config)
            let raw = try SecureEnclaveKeyManager.unwrap(wrapped: wrapped, keyTag: keyTag)
            let marker = "SECURE_ENCLAVE_P256:\(raw.base64EncodedString())"
            return SSHKeyMaterial(
                privateKey: SecureBytes(Data(marker.utf8)),
                passphrase: nil
            )
        } catch SecretStoreError.notFound {
            throw SecretStoreError.notFound
        }
    }

    // MARK: - Delete

    public static func delete(
        for keyID: UUID,
        config: SecretStoreConfiguration
    ) throws {
        // 1. Read SE key tag while references still exist
        let seKeyTag: String?
        do {
            seKeyTag = try KeychainOperations.retrievePassword(
                account: keyID.uuidString,
                service: config.sealedP256TagService,
                config: config
            )
        } catch SecretStoreError.notFound {
            seKeyTag = nil
        } catch {
            throw error
        }

        // 2. Delete SE key from Secure Enclave first
        if let keyTag = seKeyTag {
            try SecureEnclaveKeyManager.deleteKeyIfPresent(keyTag: keyTag)
        }

        // 3. Delete SE Keychain artifacts (wrapped blob + tag)
        try KeychainOperations.deleteItem(
            account: keyID.uuidString,
            service: config.sealedP256Service,
            config: config
        )
        try KeychainOperations.deleteItem(
            account: keyID.uuidString,
            service: config.sealedP256TagService,
            config: config
        )

        // 4. Delete main Keychain entries last
        try KeychainOperations.deleteItem(
            account: keyID.uuidString,
            service: config.sshKeysPrivateService,
            config: config
        )
        try KeychainOperations.deleteItem(
            account: keyID.uuidString,
            service: config.sshKeysPassphraseService,
            config: config
        )
    }

    private struct StoredSSHKeyBundle: Codable {
        let privateKey: Data
        let passphrase: Data?
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

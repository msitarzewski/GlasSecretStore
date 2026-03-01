import Testing
import Foundation
import Security
@testable import GlasSecretStore

@Suite("SSHKeyKeychainStore")
struct SSHKeyKeychainStoreTests {

    private let config: SecretStoreConfiguration
    private let keyID: UUID

    init() {
        let prefix = "test.SSHKeyStore.\(UUID().uuidString.prefix(8))"
        config = SecretStoreConfiguration(
            serviceNamePrefix: prefix,
            accessGroup: nil,
            legacyServiceNamePrefixes: []
        )
        keyID = UUID()
    }

    private func cleanupKeychain() {
        let services = [
            config.passwordsService,
            config.sshPasswordsService,
            config.sshKeysPrivateService,
            config.sshKeysPassphraseService,
            config.sealedP256Service,
            config.sealedP256TagService,
        ]
        for svc in services {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: svc,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    // MARK: - Save + Retrieve

    @Test("Save and retrieve round-trip with passphrase")
    func roundTripWithPassphrase() throws {
        defer { cleanupKeychain() }
        let pk = SecureBytes(Data("private-key-data".utf8))
        let pp = SecureBytes(Data("my-passphrase".utf8))
        try SSHKeyKeychainStore.save(privateKey: pk, passphrase: pp, for: keyID, config: config)

        let material = try SSHKeyKeychainStore.retrieve(for: keyID, config: config)
        #expect(material.privateKey.toUTF8String() == "private-key-data")
        #expect(material.passphrase?.toUTF8String() == "my-passphrase")
    }

    @Test("Save and retrieve with nil passphrase")
    func roundTripNilPassphrase() throws {
        defer { cleanupKeychain() }
        let pk = SecureBytes(Data("key-only".utf8))
        try SSHKeyKeychainStore.save(privateKey: pk, passphrase: nil, for: keyID, config: config)

        let material = try SSHKeyKeychainStore.retrieve(for: keyID, config: config)
        #expect(material.privateKey.toUTF8String() == "key-only")
        #expect(material.passphrase == nil)
    }

    @Test("Re-save with nil passphrase clears stale passphrase")
    func clearStalePassphrase() throws {
        defer { cleanupKeychain() }
        let pk = SecureBytes(Data("key".utf8))
        let pp = SecureBytes(Data("pass".utf8))
        try SSHKeyKeychainStore.save(privateKey: pk, passphrase: pp, for: keyID, config: config)

        // Re-save without passphrase
        let pk2 = SecureBytes(Data("key-v2".utf8))
        try SSHKeyKeychainStore.save(privateKey: pk2, passphrase: nil, for: keyID, config: config)

        let material = try SSHKeyKeychainStore.retrieve(for: keyID, config: config)
        #expect(material.privateKey.toUTF8String() == "key-v2")
        #expect(material.passphrase == nil)
    }

    @Test("Delete removes all artifacts")
    func deleteRemovesAll() throws {
        defer { cleanupKeychain() }
        let pk = SecureBytes(Data("key".utf8))
        let pp = SecureBytes(Data("pass".utf8))
        try SSHKeyKeychainStore.save(privateKey: pk, passphrase: pp, for: keyID, config: config)

        try SSHKeyKeychainStore.delete(for: keyID, config: config)

        #expect(throws: SecretStoreError.self) {
            try SSHKeyKeychainStore.retrieve(for: keyID, config: config)
        }
    }

    @Test("Retrieve non-existent key throws notFound")
    func retrieveNonExistent() {
        #expect(throws: SecretStoreError.self) {
            try SSHKeyKeychainStore.retrieve(for: UUID(), config: config)
        }
    }
}

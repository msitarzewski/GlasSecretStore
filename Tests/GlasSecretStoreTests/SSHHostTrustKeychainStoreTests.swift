import Testing
import Foundation
import Security
@testable import GlasSecretStore

@Suite("SSHHostTrustKeychainStore")
struct SSHHostTrustKeychainStoreTests {

    private let config: SecretStoreConfiguration

    init() {
        let prefix = "test.SSHHostTrust.\(UUID().uuidString.prefix(8))"
        config = SecretStoreConfiguration(
            serviceNamePrefix: prefix,
            accessGroup: nil,
            legacyServiceNamePrefixes: []
        )
    }

    private func cleanupKeychain() {
        let services = [
            config.sshHostTrustService,
        ]
        for service in services {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    @Test("Pinned host key normalizes host and algorithm")
    func pinnedHostKeyNormalizesLookupFields() {
        let hostKey = PinnedSSHHostKey(
            host: " Example.COM ",
            port: 22,
            algorithm: " SSH-ED25519 ",
            publicKeyData: Data("server-key".utf8)
        )

        #expect(hostKey.host == "example.com")
        #expect(hostKey.algorithm == "ssh-ed25519")
        #expect(hostKey.lookupAccount == "example.com:22")
        #expect(hostKey.sha256Fingerprint.hasPrefix("SHA256:"))
    }

    @Test("Save and retrieve pinned host key by host and port")
    func roundTripByHostAndPort() throws {
        defer { cleanupKeychain() }
        let keyData = Data("server-key".utf8)
        try SSHHostTrustKeychainStore.save(
            host: "Example.COM",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: keyData,
            config: config
        )

        let retrieved = try SSHHostTrustKeychainStore.retrieve(
            host: "example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: keyData,
            config: config
        )
        #expect(retrieved.host == "example.com")
        #expect(retrieved.port == 22)
        #expect(retrieved.algorithm == "ssh-ed25519")
        #expect(retrieved.publicKeyData == keyData)
        #expect(retrieved.sha256Fingerprint == PinnedSSHHostKey.sha256Fingerprint(for: keyData))
    }

    @Test("Upsert replaces matching pinned host key")
    func upsertReplacesMatchingPinnedHostKey() throws {
        defer { cleanupKeychain() }
        let keyData = Data("same-key".utf8)
        let oldDate = Date(timeIntervalSince1970: 100)
        let newDate = Date(timeIntervalSince1970: 200)
        try SSHHostTrustKeychainStore.save(
            PinnedSSHHostKey(
                host: "db.example.com",
                port: 22,
                algorithm: "ssh-ed25519",
                publicKeyData: keyData,
                createdAt: oldDate,
                lastSeenAt: oldDate
            ),
            config: config
        )
        try SSHHostTrustKeychainStore.save(
            PinnedSSHHostKey(
                host: "DB.EXAMPLE.COM",
                port: 22,
                algorithm: "SSH-ED25519",
                publicKeyData: keyData,
                createdAt: oldDate,
                lastSeenAt: newDate
            ),
            config: config
        )

        let retrieved = try SSHHostTrustKeychainStore.retrieve(
            host: "db.example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: keyData,
            config: config
        )
        #expect(retrieved.algorithm == "ssh-ed25519")
        #expect(retrieved.publicKeyData == keyData)
        #expect(retrieved.createdAt == oldDate)
        #expect(retrieved.lastSeenAt == newDate)
    }

    @Test("Port is part of host trust lookup")
    func portSpecificLookup() throws {
        defer { cleanupKeychain() }
        try SSHHostTrustKeychainStore.save(
            host: "example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("port-22".utf8),
            config: config
        )
        try SSHHostTrustKeychainStore.save(
            host: "example.com",
            port: 2222,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("port-2222".utf8),
            config: config
        )

        let defaultPort = try SSHHostTrustKeychainStore.retrieve(
            host: "example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("port-22".utf8),
            config: config
        )
        let alternatePort = try SSHHostTrustKeychainStore.retrieve(
            host: "example.com",
            port: 2222,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("port-2222".utf8),
            config: config
        )
        #expect(defaultPort.publicKeyData == Data("port-22".utf8))
        #expect(alternatePort.publicKeyData == Data("port-2222".utf8))
    }

    @Test("Delete removes pinned host key")
    func deleteRemovesPinnedHostKey() throws {
        defer { cleanupKeychain() }
        try SSHHostTrustKeychainStore.save(
            host: "example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("server-key".utf8),
            config: config
        )

        try SSHHostTrustKeychainStore.delete(host: "example.com", port: 22, config: config)

        #expect(throws: SecretStoreError.self) {
            try SSHHostTrustKeychainStore.retrieve(
                host: "example.com",
                port: 22,
                algorithm: "ssh-ed25519",
                publicKeyData: Data("server-key".utf8),
                config: config
            )
        }
        #expect(!SSHHostTrustKeychainStore.contains(host: "example.com", port: 22, config: config))
    }

    @Test("Base64 initializer supports migration from encoded key data")
    func base64Initializer() throws {
        let keyData = Data("server-key".utf8)
        let hostKey = try PinnedSSHHostKey(
            host: "example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyDataBase64: keyData.base64EncodedString(),
            sha256Fingerprint: "SHA256:legacy"
        )

        #expect(hostKey.publicKeyData == keyData)
        #expect(hostKey.sha256Fingerprint == "SHA256:legacy")
    }

    @Test("Evaluate reports notPinned when no host key exists")
    func evaluateNotPinned() throws {
        defer { cleanupKeychain() }
        let result = try SSHHostTrustKeychainStore.evaluate(
            host: "example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("server-key".utf8),
            config: config
        )
        #expect(result == .notPinned)
    }

    @Test("Evaluate reports trusted for matching pinned host key")
    func evaluateTrusted() throws {
        defer { cleanupKeychain() }
        let keyData = Data("server-key".utf8)
        try SSHHostTrustKeychainStore.save(
            host: "example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: keyData,
            config: config
        )

        let result = try SSHHostTrustKeychainStore.evaluate(
            host: "EXAMPLE.COM",
            port: 22,
            algorithm: "SSH-ED25519",
            publicKeyData: keyData,
            config: config
        )

        guard case .trusted(let hostKey) = result else {
            Issue.record("Expected trusted evaluation")
            return
        }
        #expect(hostKey.host == "example.com")
    }

    @Test("Evaluate reports changed for mismatched host key data")
    func evaluateChangedKey() throws {
        defer { cleanupKeychain() }
        try SSHHostTrustKeychainStore.save(
            host: "example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("old-key".utf8),
            config: config
        )

        let result = try SSHHostTrustKeychainStore.evaluate(
            host: "example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("new-key".utf8),
            config: config
        )

        guard case .changed(let previous, let current) = result else {
            Issue.record("Expected changed evaluation")
            return
        }
        #expect(previous.map(\.publicKeyData) == [Data("old-key".utf8)])
        #expect(current.publicKeyData == Data("new-key".utf8))
    }

    @Test("Multiple algorithms can be pinned for one host and port")
    func multipleAlgorithmsForSameHostPort() throws {
        defer { cleanupKeychain() }
        let ed25519 = Data("ed25519-key".utf8)
        let rsa = Data("rsa-key".utf8)
        try SSHHostTrustKeychainStore.save(
            host: "example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: ed25519,
            config: config
        )
        try SSHHostTrustKeychainStore.save(
            host: "example.com",
            port: 22,
            algorithm: "ssh-rsa",
            publicKeyData: rsa,
            config: config
        )

        let records = try SSHHostTrustKeychainStore.records(host: "example.com", port: 22, config: config)
        #expect(Set(records.map(\.algorithm)) == ["ssh-ed25519", "ssh-rsa"])

        let result = try SSHHostTrustKeychainStore.evaluate(
            host: "example.com",
            port: 22,
            algorithm: "ssh-rsa",
            publicKeyData: rsa,
            config: config
        )
        guard case .trusted(let hostKey) = result else {
            Issue.record("Expected trusted evaluation")
            return
        }
        #expect(hostKey.publicKeyData == rsa)
    }

    @Test("List returns all pinned hosts sorted by host then port")
    func allPinnedHosts() throws {
        defer { cleanupKeychain() }
        try SSHHostTrustKeychainStore.save(
            host: "b.example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("b".utf8),
            config: config
        )
        try SSHHostTrustKeychainStore.save(
            host: "a.example.com",
            port: 2222,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("a2".utf8),
            config: config
        )
        try SSHHostTrustKeychainStore.save(
            host: "a.example.com",
            port: 22,
            algorithm: "ssh-ed25519",
            publicKeyData: Data("a1".utf8),
            config: config
        )

        let hosts = try SSHHostTrustKeychainStore.allPinnedHosts(config: config)
        #expect(hosts.map(\.lookupAccount) == [
            "a.example.com:22",
            "a.example.com:2222",
            "b.example.com:22",
        ])
    }
}

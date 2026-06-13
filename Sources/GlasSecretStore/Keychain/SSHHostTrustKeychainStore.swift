//
//  SSHHostTrustKeychainStore.swift
//  GlasSecretStore
//
//  Save/retrieve/delete pinned SSH server host keys by host and port.
//

import Foundation
import Security

public enum SSHHostTrustKeychainStore: Sendable {

    public static func save(
        _ hostKey: PinnedSSHHostKey,
        config: SecretStoreConfiguration
    ) throws {
        try hostKey.validate()
        let data = try JSONEncoder().encode(hostKey)
        try KeychainOperations.saveData(
            data,
            account: hostKey.storageAccount,
            service: config.sshHostTrustService,
            config: config
        )
    }

    public static func save(
        host: String,
        port: Int,
        algorithm: String,
        publicKeyData: Data,
        config: SecretStoreConfiguration
    ) throws {
        try save(
            PinnedSSHHostKey(
                host: host,
                port: port,
                algorithm: algorithm,
                publicKeyData: publicKeyData
            ),
            config: config
        )
    }

    public static func retrieve(
        host: String,
        port: Int,
        algorithm: String,
        publicKeyData: Data,
        config: SecretStoreConfiguration
    ) throws -> PinnedSSHHostKey {
        let storageAccount = PinnedSSHHostKey.storageAccount(
            host: host,
            port: port,
            algorithm: algorithm,
            publicKeyData: publicKeyData
        )
        let data = try KeychainOperations.retrieveData(
            account: storageAccount,
            service: config.sshHostTrustService,
            config: config
        )
        let hostKey = try JSONDecoder().decode(PinnedSSHHostKey.self, from: data)
        guard hostKey.matches(algorithm: algorithm, publicKeyData: publicKeyData) else {
            throw SecretStoreError.notFound
        }
        return hostKey
    }

    public static func records(
        host: String,
        port: Int,
        config: SecretStoreConfiguration
    ) throws -> [PinnedSSHHostKey] {
        let normalizedHost = PinnedSSHHostKey.normalizedHost(host)
        return try allPinnedHosts(config: config)
            .filter { $0.host == normalizedHost && $0.port == port }
    }

    public static func contains(
        host: String,
        port: Int,
        config: SecretStoreConfiguration
    ) -> Bool {
        (try? records(host: host, port: port, config: config).isEmpty) == false
    }

    public static func delete(
        host: String,
        port: Int,
        config: SecretStoreConfiguration
    ) throws {
        try? KeychainOperations.deleteItem(
            account: PinnedSSHHostKey.lookupAccount(host: host, port: port),
            service: config.sshHostTrustService,
            config: config
        )
        for hostKey in try records(host: host, port: port, config: config) {
            try KeychainOperations.deleteItem(
                account: hostKey.storageAccount,
                service: config.sshHostTrustService,
                config: config
            )
        }
    }

    public static func allPinnedHosts(config: SecretStoreConfiguration) throws -> [PinnedSSHHostKey] {
        try KeychainOperations.allItems(service: config.sshHostTrustService, config: config)
            .map { item in
                guard let data = item[kSecValueData as String] as? Data else {
                    throw SecretStoreError.encodingFailed
                }
                return try JSONDecoder().decode(PinnedSSHHostKey.self, from: data)
            }
            .sorted { lhs, rhs in
                if lhs.host == rhs.host && lhs.port == rhs.port {
                    if lhs.algorithm == rhs.algorithm {
                        return lhs.sha256Fingerprint < rhs.sha256Fingerprint
                    }
                    return lhs.algorithm < rhs.algorithm
                }
                if lhs.host == rhs.host { return lhs.port < rhs.port }
                return lhs.host < rhs.host
            }
    }

    public static func evaluate(
        host: String,
        port: Int,
        algorithm: String,
        publicKeyData: Data,
        config: SecretStoreConfiguration
    ) throws -> SSHHostTrustEvaluation {
        let current = PinnedSSHHostKey(
            host: host,
            port: port,
            algorithm: algorithm,
            publicKeyData: publicKeyData
        )
        try current.validate()
        let previous = try records(host: host, port: port, config: config)
        guard !previous.isEmpty else {
            return .notPinned
        }
        if let matched = previous.first(where: { $0.matches(algorithm: algorithm, publicKeyData: publicKeyData) }) {
            return .trusted(matched)
        }
        return .changed(previous: previous, current: current)
    }
}

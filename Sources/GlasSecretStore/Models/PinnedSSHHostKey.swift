//
//  PinnedSSHHostKey.swift
//  GlasSecretStore
//
//  Persisted SSH server host-key trust record.
//

import CryptoKit
import Foundation

public struct PinnedSSHHostKey: Codable, Identifiable, Hashable, Sendable {
    public var id: String { storageAccount }

    public let host: String
    public let port: Int
    public let algorithm: String
    public let publicKeyData: Data
    public let sha256Fingerprint: String
    public let createdAt: Date
    public var lastSeenAt: Date

    public init(
        host: String,
        port: Int,
        algorithm: String,
        publicKeyData: Data,
        sha256Fingerprint: String? = nil,
        createdAt: Date = Date(),
        lastSeenAt: Date = Date()
    ) {
        self.host = Self.normalizedHost(host)
        self.port = port
        self.algorithm = Self.normalizedAlgorithm(algorithm)
        self.publicKeyData = publicKeyData
        self.sha256Fingerprint = sha256Fingerprint ?? Self.sha256Fingerprint(for: publicKeyData)
        self.createdAt = createdAt
        self.lastSeenAt = lastSeenAt
    }

    public init(
        host: String,
        port: Int,
        algorithm: String,
        publicKeyDataBase64: String,
        sha256Fingerprint: String? = nil,
        createdAt: Date = Date(),
        lastSeenAt: Date = Date()
    ) throws {
        guard let publicKeyData = Data(base64Encoded: publicKeyDataBase64) else {
            throw SecretStoreError.encodingFailed
        }
        self.init(
            host: host,
            port: port,
            algorithm: algorithm,
            publicKeyData: publicKeyData,
            sha256Fingerprint: sha256Fingerprint,
            createdAt: createdAt,
            lastSeenAt: lastSeenAt
        )
    }

    public var lookupAccount: String {
        Self.lookupAccount(host: host, port: port)
    }

    public var storageAccount: String {
        Self.storageAccount(host: host, port: port, algorithm: algorithm, publicKeyData: publicKeyData)
    }

    public func matches(algorithm: String, publicKeyData: Data) -> Bool {
        self.algorithm == Self.normalizedAlgorithm(algorithm) && self.publicKeyData == publicKeyData
    }

    public func refreshed(lastSeenAt: Date = Date()) -> PinnedSSHHostKey {
        PinnedSSHHostKey(
            host: host,
            port: port,
            algorithm: algorithm,
            publicKeyData: publicKeyData,
            sha256Fingerprint: sha256Fingerprint,
            createdAt: createdAt,
            lastSeenAt: lastSeenAt
        )
    }

    public static func lookupAccount(host: String, port: Int) -> String {
        "\(normalizedHost(host)):\(port)"
    }

    public static func storageAccount(host: String, port: Int, algorithm: String, publicKeyData: Data) -> String {
        "\(lookupAccount(host: host, port: port)):\(normalizedAlgorithm(algorithm)):\(sha256Fingerprint(for: publicKeyData))"
    }

    public static func normalizedHost(_ host: String) -> String {
        host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    public static func normalizedAlgorithm(_ algorithm: String) -> String {
        algorithm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    public static func sha256Fingerprint(for publicKeyData: Data) -> String {
        let digest = Data(SHA256.hash(data: publicKeyData))
            .base64EncodedString()
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
        return "SHA256:\(digest)"
    }

    public func validate() throws {
        guard !host.isEmpty else {
            throw SecretStoreError.encodingFailed
        }
        guard (1...65535).contains(port) else {
            throw SecretStoreError.encodingFailed
        }
        guard !algorithm.isEmpty else {
            throw SecretStoreError.encodingFailed
        }
        guard !publicKeyData.isEmpty else {
            throw SecretStoreError.encodingFailed
        }
    }
}

public enum SSHHostTrustEvaluation: Codable, Hashable, Sendable {
    case notPinned
    case trusted(PinnedSSHHostKey)
    case changed(previous: [PinnedSSHHostKey], current: PinnedSSHHostKey)
}

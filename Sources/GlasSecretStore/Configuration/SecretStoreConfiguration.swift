//
//  SecretStoreConfiguration.swift
//  GlasSecretStore
//
//  Value-type configuration for Keychain operations.
//  Each app creates its own configuration at launch.
//

import Foundation
import Security

/// Per-item protection applied in addition to the configuration's access
/// group and service isolation.
public enum SecretAccessPolicy: String, Codable, CaseIterable, Sendable {
    /// Available whenever the configured Keychain accessibility permits.
    case standard

    /// Requires device-owner authentication for every retrieval.
    case userPresence
}

/// Canonical UUID-scoped account names for credentials intentionally shared by
/// Glass-family apps. Keeping this identity contract in GlasSecretStore prevents
/// each app from growing a subtly incompatible account namespace while retaining
/// per-profile isolation for otherwise identical endpoints.
public enum GlassFamilyCredentialAccount: Sendable {
    public static func databasePassword(profileID: UUID) -> String {
        "database:\(profileID.uuidString.lowercased())"
    }

    public static func sshPassword(profileID: UUID) -> String {
        "ssh:\(profileID.uuidString.lowercased())"
    }
}

public struct SecretStoreConfiguration: @unchecked Sendable {
    /// Primary service name prefix (e.g. "sh.glas").
    /// Keychain service names are derived as "\(prefix).passwords", "\(prefix).sshkeys.private", etc.
    public let serviceNamePrefix: String

    /// Keychain access group for cross-app sharing (e.g. "TEAMID.sh.glas.shared").
    /// When non-nil, injected into every SecItem* call.
    public let accessGroup: String?

    /// Keychain accessibility level.
    public let accessibility: CFString

    /// Migration marker comment stamped on migrated items.
    public let migrationMarkerComment: String

    /// Legacy service name prefixes to search during fallback retrieval.
    /// For example, glassdb passes `["app.glassdb"]` to find items saved before unification.
    public let legacyServiceNamePrefixes: [String]

    /// Opts macOS callers into the modern data-protection Keychain. Other
    /// Apple platforms already use it and ignore this setting.
    public let useDataProtectionKeychain: Bool

    public init(
        serviceNamePrefix: String = "sh.glas",
        accessGroup: String? = nil,
        accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        migrationMarkerComment: String = "sh.glas.secretstore.v1",
        legacyServiceNamePrefixes: [String] = [],
        useDataProtectionKeychain: Bool = false
    ) {
        self.serviceNamePrefix = serviceNamePrefix
        self.accessGroup = accessGroup
        self.accessibility = accessibility
        self.migrationMarkerComment = migrationMarkerComment
        self.legacyServiceNamePrefixes = legacyServiceNamePrefixes
        self.useDataProtectionKeychain = useDataProtectionKeychain
    }

    // MARK: - Derived Service Names

    public var passwordsService: String { "\(serviceNamePrefix).passwords" }
    public var sshPasswordsService: String { "\(serviceNamePrefix).sshpasswords" }
    public var sshKeysPrivateService: String { "\(serviceNamePrefix).sshkeys.private" }
    public var sshKeysPassphraseService: String { "\(serviceNamePrefix).sshkeys.passphrase" }
    public var sealedP256Service: String { "\(serviceNamePrefix).sshkeys.sealedp256" }
    public var sealedP256TagService: String { "\(serviceNamePrefix).sshkeys.sealedp256.tag" }
    public var sshHostTrustService: String { "\(serviceNamePrefix).ssh.hosttrust" }
}

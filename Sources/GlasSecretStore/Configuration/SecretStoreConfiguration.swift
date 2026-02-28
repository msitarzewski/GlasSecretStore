//
//  SecretStoreConfiguration.swift
//  GlasSecretStore
//
//  Value-type configuration for Keychain operations.
//  Each app creates its own configuration at launch.
//

import Foundation
import Security

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

    public init(
        serviceNamePrefix: String = "sh.glas",
        accessGroup: String? = nil,
        accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        migrationMarkerComment: String = "sh.glas.secretstore.v1",
        legacyServiceNamePrefixes: [String] = []
    ) {
        self.serviceNamePrefix = serviceNamePrefix
        self.accessGroup = accessGroup
        self.accessibility = accessibility
        self.migrationMarkerComment = migrationMarkerComment
        self.legacyServiceNamePrefixes = legacyServiceNamePrefixes
    }

    // MARK: - Derived Service Names

    public var passwordsService: String { "\(serviceNamePrefix).passwords" }
    public var sshPasswordsService: String { "\(serviceNamePrefix).sshpasswords" }
    public var sshKeysPrivateService: String { "\(serviceNamePrefix).sshkeys.private" }
    public var sshKeysPassphraseService: String { "\(serviceNamePrefix).sshkeys.passphrase" }
    public var sealedP256Service: String { "\(serviceNamePrefix).sshkeys.sealedp256" }
    public var sealedP256TagService: String { "\(serviceNamePrefix).sshkeys.sealedp256.tag" }
}

//
//  SSHKeyMaterial.swift
//  GlasSecretStore
//
//  Retrieved SSH key material (private key + optional passphrase).
//

import Foundation

public struct SSHKeyMaterial: Sendable {
    public let privateKey: String
    public let passphrase: String?

    public init(privateKey: String, passphrase: String?) {
        self.privateKey = privateKey
        self.passphrase = passphrase
    }
}

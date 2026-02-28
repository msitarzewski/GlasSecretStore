//
//  SecretStoreError.swift
//  GlasSecretStore
//
//  Unified error type replacing both apps' KeychainError.
//

import Foundation

public enum SecretStoreError: Error, LocalizedError, Sendable {
    case unableToSave
    case notFound
    case unableToDelete
    case unsupportedSSHKeyType
    case secureEnclaveUnavailable
    case secureEnclaveOperationFailed
    case encodingFailed

    public var errorDescription: String? {
        switch self {
        case .unableToSave:
            return "Unable to save secure item in Keychain."
        case .notFound:
            return "Requested secure item was not found in Keychain."
        case .unableToDelete:
            return "Unable to delete secure item from Keychain."
        case .unsupportedSSHKeyType:
            return "Unsupported SSH key type. Use RSA or ED25519."
        case .secureEnclaveUnavailable:
            return "Secure Enclave is unavailable on this device."
        case .secureEnclaveOperationFailed:
            return "Secure Enclave operation failed."
        case .encodingFailed:
            return "Failed to encode value for Keychain storage."
        }
    }
}

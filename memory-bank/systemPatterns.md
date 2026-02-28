# System Patterns — GlasSecretStore

## Architecture: Layered Enum-Based Services

All service types are **enums with static methods** (no instances). This enforces statelessness and `Sendable` conformance throughout.

```
Configuration (value type)
    ↓ injected into
KeychainOperations (low-level SecItem CRUD)
    ↓ used by
SSHKeyKeychainStore (SSH key save/retrieve/delete)
SecureEnclaveKeyManager (P256 wrap/unwrap)
SecretStoreMigrationManager (v0→v1 stamp migration)
```

## Key Patterns

### Configuration Injection
Every Keychain operation takes a `SecretStoreConfiguration` parameter — no singletons, no global state. Service names are derived from `config.serviceNamePrefix`.

### Fallback Retrieval
`retrievePasswordWithFallback` tries the primary service name, then iterates `config.legacyServiceNamePrefixes` for backward compatibility.

### Update-Then-Add (Atomic Upsert)
`saveData` tries `SecItemUpdate` first; on `errSecItemNotFound` falls back to `SecItemAdd`. Eliminates the race window of the former delete-before-add pattern. Payloads > 1 MB are rejected with `payloadTooLarge`.

### Backward-Compatible Codable
`StoredSSHKey.init(from:)` uses `decodeIfPresent` with defaults for fields added after v1, so older persisted data deserializes cleanly.

### Migration Marker
Items stamped with `config.migrationMarkerComment` in `kSecAttrComment` to distinguish migrated vs. legacy items. `itemCount(legacyOnly:)` filters on this.

### SecureBytes
`SecureBytes` wraps sensitive key material in an `mlock`'d buffer that is zeroed on dealloc. `SSHKeyMaterial.privateKey` and `.passphrase` use this type. Retrieve paths go through `retrieveData` (not `retrievePassword`) to avoid intermediate `String` copies.

### Secure Enclave Flow
1. Generate P256 key in SE (tagged by UUID)
2. Wrap private key data with SE public key
3. Store wrapped blob + key tag in Keychain
4. Unwrap via SE private key on retrieval

### Secure Enclave Delete Order
Delete reads the SE tag first (while references exist), deletes the SE key, then SE artifacts, then main Keychain entries last — prevents orphaned keys.

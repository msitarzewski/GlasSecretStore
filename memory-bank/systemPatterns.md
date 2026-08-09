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
SSHHostTrustKeychainStore (SSH host identity and rotation history)
```

The current implementation provides Keychain operations, SSH-key lifecycle,
Secure Enclave wrapping, migration support, host trust, and canonical
Glass-family UUID account names. A synchronized credential catalog and eligible
cross-device item flow are approved planned work, not current capability.

## Glass-Family Credential Contract

### Ownership Boundary

- GlasSecretStore owns stable `CredentialID`, credential kind, availability,
  storage/mobility/authentication policy, secret material, migration, deletion,
  and SSH host trust.
- It does not own `EndpointProfile`, CloudKit endpoint records, database overlays,
  terminal/workspace settings, onboarding UI, or connection execution.
- Consumer apps exchange stable endpoint-to-credential references; they never
  derive family identity from mutable `user@host:port` fields or create parallel
  catalogs.

### Orthogonal Policy Axes

- **App sharing**: which signed Glass-family apps may discover and retrieve a
  credential through an approved access group.
- **Device mobility**: whether eligible material may synchronize to another Apple
  device after explicit consent.
- **Authentication kind**: password, imported key/passphrase, device-bound Secure
  Enclave representation, user-presence record, or another supported method.
- These axes must be modeled independently. `sharedWithGlass` does not imply
  synchronizable, and synchronizable does not remove authentication or trust
  requirements.

### Availability Contract

- Resolve an explicit local state before a consumer connects: available locally,
  pending mobility, iCloud account action required, local enrollment required,
  host-trust review required, revoked/deleted, or unsupported.
- Consumer-facing mappings are **Ready**, **Still Syncing**, **Sign In to
  iCloud**, **Set Up This Key**, and **Review Fingerprint**.
- Metadata arrival never proves secret availability. Never silently substitute a
  password or exportable key for missing device-bound material.

### Planned Synchronization Boundary

- Current configurations default to `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
  and do not implement `kSecAttrSynchronizable`; this remains the migration
  baseline until the planned work passes.
- Only explicitly eligible passwords, passphrases, and exportable imported keys
  may enter the Apple-protected mobility path. Secure Enclave and
  user-presence-protected material remains device-bound.
- Synchronizable item CRUD must set/query the correct Keychain attributes
  consistently, handle duplicate/concurrent records deterministically, and never
  leak secret material into the non-secret catalog or CloudKit metadata.
- Migration is forward-only, atomic-add-if-absent, conflict-preserving,
  rollback-aware, and safe under app-version skew. Deletion, revocation, and
  rotation must define cross-device propagation and recovery before shipping.
- Host trust remains an explicit device/security decision unless separately
  approved; a synced endpoint or credential never auto-approves a fingerprint.

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

### Two-Pass Bulk Keychain Query
`allItems` cannot combine `kSecReturnData` with `kSecMatchLimitAll` on macOS (returns `errSecParam -50`). The pattern is: (1) bulk-fetch attributes with `kSecMatchLimitAll`, (2) fetch data per-item with `kSecMatchLimitOne` using the item's account.

### SecureBytes
`SecureBytes` wraps sensitive key material in an `mlock`'d buffer that is zeroed on dealloc. `SSHKeyMaterial.privateKey` and `.passphrase` use this type. Retrieve paths go through `retrieveData` (not `retrievePassword`) to avoid intermediate `String` copies.

### Secure Enclave Flow
1. Generate P256 key in SE (tagged by UUID)
2. Wrap private key data with SE public key
3. Store wrapped blob + key tag in Keychain
4. Unwrap via SE private key on retrieval

### Secure Enclave Delete Order
Delete reads the SE tag first (while references exist), deletes the SE key, then SE artifacts, then main Keychain entries last — prevents orphaned keys.

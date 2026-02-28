# GlasSecretStore

Swift package providing unified Keychain and Secure Enclave operations for [glas.sh](https://glas.sh) apps. Extracted from shared code between the glas.sh SSH client and glassdb database client.

## Requirements

- Swift 6.0+
- macOS 15+ or visionOS 2+

## Installation

Add the dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/glassh/GlasSecretStore.git", from: "1.0.0"),
]
```

Then add `"GlasSecretStore"` to your target's dependencies.

## Usage

### Configuration

Every operation takes a `SecretStoreConfiguration`. Create one at app launch:

```swift
import GlasSecretStore

let config = SecretStoreConfiguration(
    serviceNamePrefix: "sh.glas",
    accessGroup: "TEAMID.sh.glas.shared",  // optional, for cross-app sharing
    legacyServiceNamePrefixes: ["app.glassdb"]  // optional, for migration
)
```

### Passwords

```swift
// Save
try KeychainOperations.savePassword("s3cret", account: "user@host", service: config.passwordsService, config: config)

// Retrieve
let password = try KeychainOperations.retrievePassword(account: "user@host", service: config.passwordsService, config: config)

// Retrieve with legacy fallback
let password = try KeychainOperations.retrievePasswordWithFallback(
    account: "user@host",
    primaryService: config.passwordsService,
    legacySuffix: "passwords",
    config: config
)

// Delete
try KeychainOperations.deletePassword(account: "user@host", service: config.passwordsService, config: config)
```

### SSH Keys

```swift
let keyID = UUID()

// Save a key (private key + optional passphrase)
try SSHKeyKeychainStore.save(privateKey: pemString, passphrase: "passphrase", for: keyID, config: config)

// Retrieve
let material = try SSHKeyKeychainStore.retrieve(for: keyID, config: config)
// material.privateKey, material.passphrase

// Delete (cleans up passphrase and Secure Enclave artifacts too)
try SSHKeyKeychainStore.delete(for: keyID, config: config)
```

### Secure Enclave (P256)

Hardware-backed key wrapping for devices with a Secure Enclave:

```swift
let keyTag = SecureEnclaveKeyManager.keyTag(for: keyID)

// Wrap data with a Secure Enclave P256 key
let wrapped = try SecureEnclaveKeyManager.wrap(data: sensitiveData, keyTag: keyTag)

// Store the wrapped blob
try SSHKeyKeychainStore.saveSecureEnclaveWrapped(wrapped, keyTag: keyTag, for: keyID, config: config)

// Retrieve and unwrap
let (wrappedData, tag) = try SSHKeyKeychainStore.retrieveSecureEnclaveWrapped(for: keyID, config: config)
let decrypted = try SecureEnclaveKeyManager.unwrap(wrapped: wrappedData, keyTag: tag)
```

### Migration

Stamps legacy Keychain items with a migration marker and correct accessibility level:

```swift
let migrator = SecretStoreMigrationManager(config: config)
let report = migrator.runScaffoldIfNeeded()
// report?.migratedItemCount, report?.failedItemCount, etc.
```

## Architecture

```
SecretStoreConfiguration          (value type, injected everywhere)
    │
    ├── KeychainOperations        (low-level SecItem CRUD)
    │       │
    │       ├── SSHKeyKeychainStore       (SSH key save/retrieve/delete)
    │       └── SecretStoreMigrationManager   (v0 → v1 migration)
    │
    └── SecureEnclaveKeyManager   (P256 wrap/unwrap)
```

All service types are stateless enums with static methods — no singletons, fully `Sendable`, safe for Swift 6 strict concurrency.

## License

MIT

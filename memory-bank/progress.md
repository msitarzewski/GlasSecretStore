# Progress — GlasSecretStore

## Completed
- Core library implementation (13 source files)
- Keychain CRUD operations with access group injection
- SSH key save/retrieve/delete with passphrase support
- Secure Enclave P256 wrap/unwrap
- v0→v1 migration scaffold
- Backward-compatible Codable on StoredSSHKey
- Configuration-driven service names
- Repository setup (git init, initial commit)
- Security hardening (2026-02-28):
  - `SecureBytes` type — mlock/munlock, zero-on-dealloc for key material
  - Atomic upsert (update-then-add) replacing delete-before-add
  - `allItems` / `updateItem` scoped to `package`
  - `updateItem` now throws with `updateFailed` error
  - `payloadTooLarge` size guard (1 MB) on `saveData`
  - Empty string guard on `savePassword`
  - Conditional migration version stamp (only on zero failures)
  - Secure Enclave delete order fix (read tag before deleting references)
  - `unsafeBitCast` → type-checked `as!` cast
  - `SSHKeyMaterial` uses `SecureBytes` instead of `String`

## Completed (continued)
- Consumer app migration to SecureBytes API (2026-02-28):
  - glas.sh: `KeychainManager.swift` save boundary wraps `String` → `SecureBytes`
  - glas.sh: `SettingsManager.swift` + `Models.swift` retrieve boundaries convert back via `.toUTF8String()` / `.toData()`
  - glassdb: `KeychainManager.swift` save boundary wraps `String` → `SecureBytes`
  - glassdb: `DatabaseSessionManager.swift` retrieve boundary converts via `.toUTF8String()`
  - Both apps compile clean; public wrapper API unchanged

## Completed (continued)
- Test target and allItems bugfix (2026-03-01):
  - Added `GlasSecretStoreTests` test target (51 tests across 7 files, 12 suites)
  - Fixed `allItems` macOS bug: `kSecReturnData + kSecMatchLimitAll` returns `errSecParam (-50)`
  - Fix: two-pass approach — bulk-fetch attributes, then retrieve data per-item
  - Tests cover: SecureBytes, all model types, Configuration, KeychainOperations, SSHKeyKeychainStore, MigrationManager, SecureEnclaveKeyManager
  - Migration stamp test confirmed the fix — items actually get migrated now

## Completed (continued)
- SSH host trust storage (2026-06-13):
  - Added `PinnedSSHHostKey` model for normalized host/port/algorithm trust records, SHA256 fingerprints, multi-key storage accounts, and base64 migration from consumer app records
  - Added `SSHHostTrustKeychainStore` with save, exact retrieve, host/port records, contains, delete, all-host listing, and pure changed-key evaluation
  - Added `SecretStoreConfiguration.sshHostTrustService`
  - Kept UI policy out of the package and preserved existing public APIs by reusing `SecretStoreError.encodingFailed` for validation failures
  - Tests now pass at 62 tests across 13 suites

## Current Working Contract (2026-08)

- [x] Repository CI runs package tests and a Release build for pushes and pull requests
- [x] Package manifest declares visionOS 26, macOS 26, and iOS/iPadOS 26
- [x] Shared access-group configuration and canonical Glass-family UUID account
  helpers support current same-device consumer integration
- [x] Fresh 2026-08-09 package verification passes 76/76 tests across 13 suites,
  including the canonical Glass-family UUID account test
- [x] Product/architecture direction approved for the **My Connections**
  credential authority; implementation status remains explicit below

## Not Started
- Stable family credential/availability catalog independent of app profile IDs
- Eligible password/passphrase/imported-key synchronization and migration
- Cross-device deletion, revocation, rotation, conflict, recovery, offline, and
  iCloud account-change semantics
- Signed cross-app/device acceptance across glas.sh and glassdb
- Device-bound enrollment UX contract for Secure Enclave/user-presence material

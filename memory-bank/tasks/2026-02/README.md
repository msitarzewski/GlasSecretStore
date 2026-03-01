# February 2026 — GlasSecretStore

## Tasks Completed

### 2026-02-28: Repository Initialization
- Initialized git repository
- Created `.gitignore` for Swift/SPM
- Set up memory bank with core files
- Initial commit of all source files
- See: [280226_repo-init.md](./280226_repo-init.md)

### 2026-02-28: Security Hardening
- Created `SecureBytes` type (mlock/munlock, zero-on-dealloc)
- Replaced delete-before-add with atomic update-then-add upsert
- Scoped `allItems` and `updateItem` to `package`
- Made `updateItem` throw with new `updateFailed` error case
- Added `payloadTooLarge` size guard (1 MB) on `saveData`
- Added empty string guard on `savePassword`
- Fixed migration version stamp to be conditional on zero failures
- Fixed Secure Enclave delete order (read tag before deleting references)
- Replaced `unsafeBitCast` with type-checked `as!` cast
- Changed `SSHKeyMaterial` from `String` to `SecureBytes`
- Files: `SecureBytes.swift` (new), `SecretStoreError.swift`, `SSHKeyMaterial.swift`, `KeychainOperations.swift`, `SSHKeyKeychainStore.swift`, `SecureEnclaveKeyManager.swift`, `SecretStoreMigrationManager.swift`

### 2026-02-28: Consumer App Migration to SecureBytes API
- Updated glas.sh `KeychainManager.swift` save boundary: `String` → `SecureBytes(Data(_.utf8))`
- Updated glas.sh `SettingsManager.swift` and `Models.swift` retrieve boundaries: `.toUTF8String()` / `.toData()`
- Updated glassdb `KeychainManager.swift` save boundary: same pattern
- Updated glassdb `DatabaseSessionManager.swift` retrieve boundary: `.toUTF8String()`
- Public wrapper API unchanged — conversion happens inside `KeychainManager`
- Both apps compile clean

### 2026-03-01: Test Target + allItems Bugfix
- Added `GlasSecretStoreTests` test target with 51 tests across 7 files
- Discovered and fixed production bug in `KeychainOperations.allItems`: macOS rejects `kSecReturnData + kSecMatchLimitAll` with `errSecParam (-50)`, causing migration to silently skip all items
- Fix: two-pass approach — bulk-fetch attributes only, then retrieve data per-item
- Test coverage: SecureBytes (8), Models (14), Configuration (4), KeychainOperations (12), SSHKeyKeychainStore (5), MigrationManager (4), SecureEnclaveKeyManager (3)
- Keychain test isolation: unique `serviceNamePrefix` per test class, `defer` cleanup
- Files: `Package.swift`, `KeychainOperations.swift` (bugfix), 7 new test files
- See: [010301_test-target.md](./010301_test-target.md)

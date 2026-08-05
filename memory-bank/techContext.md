# Tech Context — GlasSecretStore

## Stack
- **Language**: Swift 6.2 tools baseline (strict concurrency)
- **Package Manager**: Swift Package Manager
- **Platforms**: visionOS 26+, macOS 26+, iOS/iPadOS 26+
- **Frameworks**: Foundation, Security

## Dependencies
None — zero external dependencies. Pure Apple frameworks only.

## Concurrency
- All public types are `Sendable`
- Enums with static methods are inherently thread-safe
- `SecretStoreConfiguration` is `@unchecked Sendable` (immutable value type with `CFString` field)
- `SecretStoreMigrationManager` is `@unchecked Sendable` (class with `nonisolated(unsafe)` UserDefaults)

## Build
```bash
swift build
```

## Testing
- Framework: Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`)
- Current verification (2026-08-09): 76/76 tests across 13 suites
- Keychain tests use unique `serviceNamePrefix` per class + `defer` cleanup for isolation
- Secure Enclave tests are minimal (unavailable on Simulator)
- Run: `swift test`

## Known macOS Keychain Behavior
- `kSecReturnData + kSecMatchLimitAll` returns `errSecParam (-50)` — must use two-pass (attributes bulk, data per-item)
- Unsigned test processes have the same limitation; production signed apps do too (it's a SecItem API constraint, not a signing issue)

## Current Synchronization Boundary

- `SecretStoreConfiguration` defaults to
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- No `kSecAttrSynchronizable` item/catalog flow is implemented in the current
  package.
- Shared Keychain access groups enable authorized same-device app sharing; they
  do not prove cross-device mobility.
- The approved next contract permits explicit synchronization only for eligible
  exportable credentials. Secure Enclave and user-presence-protected material
  remains device-bound and requires local enrollment.

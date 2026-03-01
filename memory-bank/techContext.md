# Tech Context — GlasSecretStore

## Stack
- **Language**: Swift 6.0 (strict concurrency)
- **Package Manager**: Swift Package Manager
- **Platforms**: visionOS 2+, macOS 15+
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
- 51 tests across 7 files, 12 suites
- Keychain tests use unique `serviceNamePrefix` per class + `defer` cleanup for isolation
- Secure Enclave tests are minimal (unavailable on Simulator)
- Run: `swift test`

## Known macOS Keychain Behavior
- `kSecReturnData + kSecMatchLimitAll` returns `errSecParam (-50)` — must use two-pass (attributes bulk, data per-item)
- Unsigned test processes have the same limitation; production signed apps do too (it's a SecItem API constraint, not a signing issue)

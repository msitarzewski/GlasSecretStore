# Project Rules — GlasSecretStore

## Conventions

### File Organization
```
Sources/GlasSecretStore/
├── Models/          — Value types, enums, error types
├── Keychain/        — SecItem operations
├── SecureEnclave/   — Hardware-backed key operations
├── Configuration/   — App-provided config
└── Migration/       — Version migration logic
```

### Naming
- Enum-based services: `public enum ServiceName: Sendable { static func ... }`
- Configuration: Value type, injected as parameter (never global)
- Errors: Single unified `SecretStoreError` enum
- Models: `Codable + Sendable + Hashable` where applicable

### API Design
- All public APIs take `SecretStoreConfiguration` as parameter
- No singletons or shared instances
- Prefer `throws` over optional returns for operations that can fail
- Use `try?` internally for non-critical cleanup (e.g., deleting stale passphrases)

### Concurrency
- Swift 6.0 strict concurrency mode
- All public types must be `Sendable`
- Use `@unchecked Sendable` only for types with immutable semantics but non-Sendable fields (e.g., `CFString`)

### Security
- Never expose raw secret data (`Data`, `String`) via public API — use `SecureBytes`
- Bulk Keychain queries (`allItems`) must be `package`-scoped, not `public`
- Internal-only helpers (`updateItem`) should be `package`-scoped and `throws`
- Reject empty strings before Keychain save (prevents silent data loss via upsert)
- Migration version stamp must be conditional on zero failures

### Testing
- Use Swift Testing framework (`@Suite`, `@Test`, `#expect`)
- Keychain test isolation: unique `serviceNamePrefix` per test class via `"test.\(type).\(UUID().prefix(8))"`
- Cleanup: `defer { cleanupKeychain() }` in every test touching Keychain
- UserDefaults isolation: unique `suiteName` per test class, cleaned up in defer
- Never combine `kSecReturnData` + `kSecMatchLimitAll` in production or tests — use two-pass
- Secure Enclave: only test graceful failure paths (unavailable on Simulator)

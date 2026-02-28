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

## No Tests Yet
Test target not defined in `Package.swift`. To be added.

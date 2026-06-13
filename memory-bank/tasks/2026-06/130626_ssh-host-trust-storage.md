# 130626_ssh-host-trust-storage

## Objective
Extend GlasSecretStore as the shared secret/security substrate for glas.sh and glassdb.app by adding reusable SSH host trust storage for pinned server host keys, changed-key detection, migration-friendly host/port lookup, CRUD APIs, and tests while keeping UI policy out of the package.

## Outcome
- Added `PinnedSSHHostKey` for persisted SSH server host trust records.
- Added `SSHHostTrustEvaluation` with policy-neutral states: not pinned, trusted, or changed.
- Added `SSHHostTrustKeychainStore` as a stateless enum service over existing Keychain primitives.
- Added `SecretStoreConfiguration.sshHostTrustService` for config-derived host trust storage.
- Preserved existing public APIs by avoiding changes to `SecretStoreError`.
- Kept `lastSeenAt` caller-controlled through `PinnedSSHHostKey.refreshed()`.

## Files Modified
- `Sources/GlasSecretStore/Models/PinnedSSHHostKey.swift` - New `Codable`, `Hashable`, `Sendable` host-key model, exact storage account generation, SHA256 fingerprinting, validation, and base64 migration initializer.
- `Sources/GlasSecretStore/Keychain/SSHHostTrustKeychainStore.swift` - New Keychain-backed host trust CRUD and evaluation service.
- `Sources/GlasSecretStore/Configuration/SecretStoreConfiguration.swift` - Added `sshHostTrustService`.
- `Tests/GlasSecretStoreTests/ConfigurationTests.swift` - Added derived service-name assertion.
- `Tests/GlasSecretStoreTests/SSHHostTrustKeychainStoreTests.swift` - Added host trust model, CRUD, multi-key, changed-key, listing, deletion, and migration initializer coverage.

## Patterns Applied
- `memory-bank/systemPatterns.md#Architecture: Layered Enum-Based Services`
- `memory-bank/systemPatterns.md#Configuration Injection`
- `memory-bank/systemPatterns.md#Update-Then-Add (Atomic Upsert)`
- `memory-bank/systemPatterns.md#Two-Pass Bulk Keychain Query`
- `memory-bank/projectRules.md#Conventions`
- `memory-bank/projectRules.md#Testing`

## Integration Points
- `SecretStoreConfiguration.sshHostTrustService` derives the shared host-trust service name from each app's configured prefix.
- `SSHHostTrustKeychainStore.save(_:config:)` stores validated `PinnedSSHHostKey` JSON using `KeychainOperations.saveData`.
- `SSHHostTrustKeychainStore.records(host:port:config:)` provides migration-friendly lookup by normalized host and port.
- `SSHHostTrustKeychainStore.retrieve(host:port:algorithm:publicKeyData:config:)` retrieves an exact pinned key by host, port, algorithm, and key bytes.
- `SSHHostTrustKeychainStore.evaluate(host:port:algorithm:publicKeyData:config:)` reports trust state without making UI accept/reject decisions.

## Architectural Decisions
- Decision: Store multiple pinned keys per host/port using a storage key that includes host, port, algorithm, and SHA256 fingerprint.
- Rationale: SSH servers can present different host-key algorithms during negotiation, so multi-key host/port storage avoids treating normal algorithm variation as a replacement.
- Decision: Keep evaluation pure and leave `lastSeenAt` updates to callers.
- Rationale: The package should provide reusable security state, not UI/session policy.
- Decision: Use `SecretStoreError.encodingFailed` for validation failures.
- Rationale: Adding a public `SecretStoreError` case would risk source breakage for exhaustive downstream switches.

## QA
- `swift test` - Passed, 62 tests.
- `swift test --filter SSHHostTrustKeychainStore` - Passed, 11 tests.
- `git diff --check` - Passed.

## Artifacts
- Branch: `codex-ssh-host-trust-storage`

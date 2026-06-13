# June 2026 — GlasSecretStore

## Tasks Completed

### 2026-06-13: SSH Host Trust Storage
- Added reusable SSH host trust storage for glas.sh and glassdb.app.
- Added `PinnedSSHHostKey` model with normalized host/algorithm fields, host/port lookup keys, multi-key storage keys, SHA256 fingerprints, `lastSeenAt`, validation, and base64 migration initializer.
- Added `SSHHostTrustKeychainStore` with config-injected Keychain CRUD, exact key retrieval, host/port record listing, deletion, all-host listing, and pure changed-key evaluation.
- Added `sshHostTrustService` derived service name to `SecretStoreConfiguration`.
- Tests: `swift test` passed with 62 tests; `swift test --filter SSHHostTrustKeychainStore` passed with 11 tests; `git diff --check` passed.
- Files: `PinnedSSHHostKey.swift`, `SSHHostTrustKeychainStore.swift`, `SecretStoreConfiguration.swift`, `ConfigurationTests.swift`, `SSHHostTrustKeychainStoreTests.swift`.
- See: [130626_ssh-host-trust-storage.md](./130626_ssh-host-trust-storage.md)

# Active Context — GlasSecretStore

## Current Focus (June 2026)
- SSH host trust storage added for shared glas.sh and glassdb.app security substrate
- Test suite complete (62 tests, all passing)
- Package is functional and in use by glas.sh and glassdb

## Open Items
- No CI/CD pipeline

## Recent Activity
- 2026-06-13: SSH host trust storage — pinned host key model, multi-key Keychain store, changed-key evaluation, migration initializer, 11 focused tests
- 2026-03-01: Test target added — 51 tests across 7 files covering all modules
- 2026-03-01: Bugfix — `allItems` two-pass fix for macOS `errSecParam (-50)` on `kSecReturnData + kSecMatchLimitAll`
- 2026-02-28: Consumer app migration — glas.sh (3 files) and glassdb (2 files) updated for SecureBytes API
- 2026-02-28: Security hardening — SecureBytes, atomic upsert, scope tightening, delete order fix, migration stamp fix
- 2026-02-28: Git repo initialized, memory bank created, initial commit

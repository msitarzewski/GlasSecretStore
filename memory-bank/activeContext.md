# Active Context — GlasSecretStore

## Current Focus (August 2026)
- Package is functional and used by glas.sh and glassdb across their native
  Vision Pro, Mac, iPad, and iPhone targets
- SSH host trust, forward-only migration, artifact-aware SSH-key deletion, and
  canonical Glass-family UUID account helpers form the current shared security
  substrate
- Fresh 2026-08-09 package verification passes 76/76 tests across 13 suites,
  including the canonical Glass-family UUID account contract
- Current Keychain configurations remain `ThisDeviceOnly`; no synchronized
  credential catalog or eligible `kSecAttrSynchronizable` item flow is implemented
- Approved next program: the *Magic / First Class* **My Connections** contract,
  with stable credential identity, honest availability, explicit mobility
  consent, and device-bound Secure Enclave/user-presence enrollment

## Open Items
- Define the stable family `CredentialID` and non-secret availability catalog
  independently from either app's connection UUID
- Implement and migrate eligible Apple-protected credential mobility without
  weakening device-bound material
- Define deletion, revocation, rotation, recovery, account-change, offline, and
  app-version-skew behavior
- Prove correctly signed glas.sh/glassdb interoperability and cross-device
  behavior on supported physical devices
- Keep host-trust review explicit when a connection first appears on a device

## Recent Activity
- 2026-08-09: Added repository CI for package tests and Release builds on the
  same Xcode 27 runner class used by the glassdb consumer
- 2026-06-13: SSH host trust storage — pinned host key model, multi-key Keychain store, changed-key evaluation, migration initializer, 11 focused tests
- 2026-03-01: Test target added — 51 tests across 7 files covering all modules
- 2026-03-01: Bugfix — `allItems` two-pass fix for macOS `errSecParam (-50)` on `kSecReturnData + kSecMatchLimitAll`
- 2026-02-28: Consumer app migration — glas.sh (3 files) and glassdb (2 files) updated for SecureBytes API
- 2026-02-28: Security hardening — SecureBytes, atomic upsert, scope tightening, delete order fix, migration stamp fix
- 2026-02-28: Git repo initialized, memory bank created, initial commit

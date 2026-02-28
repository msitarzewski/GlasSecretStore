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

## Not Started
- Test target
- CI/CD
- Remote repository / public hosting
- Consumer app migration (glas.sh, glassdb) to new SecureBytes API

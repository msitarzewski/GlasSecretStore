# Product Context — GlasSecretStore

## User Goals
- Developers and power users managing SSH keys across glas.sh and glassdb
- Keys should persist securely across app launches, backed by Keychain
- Secure Enclave keys provide hardware-backed protection where available
- Migration from older key formats should be seamless and invisible

## Market Context
- Part of the glas.sh ecosystem (visionOS-first SSH/database tools)
- Competes with platform Keychain wrappers but specialized for SSH key lifecycle

## Integration Points
- Both consumer apps depend on this package via SPM local path or git dependency
- Apps provide their own `SecretStoreConfiguration` at launch (service prefix, access group, legacy prefixes)

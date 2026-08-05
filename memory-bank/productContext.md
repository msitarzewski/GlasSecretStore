# Product Context — GlasSecretStore

## User Goals
- Developers and power users expect **My Connections** to use the same eligible
  SSH identity across glas.sh and glassdb on their Apple devices
- Credentials should persist securely across app launches and become available
  across authorized Glass apps/devices only according to explicit policy
- Secure Enclave keys provide hardware-backed protection where available
- Migration from older key formats should be seamless and invisible
- Missing or delayed credentials should produce a clear recovery action rather
  than a broken connection or silent fallback

## Market Context
- Part of the Glass family of native Apple-platform SSH/database tools
- Competes with platform Keychain wrappers but specialized for SSH key lifecycle

## Integration Points
- Both consumer apps depend on this package via SPM local path or git dependency
- Apps provide their own `SecretStoreConfiguration` at launch (service prefix, access group, legacy prefixes)

## Magic / First Class Contract

- GlasSecretStore is invisible infrastructure. Users see **Ready**, **Still
  Syncing**, **Sign In to iCloud**, **Set Up This Key**, or **Review Fingerprint**;
  they do not need package, Keychain-group, item-attribute, or migration language.
- No proprietary Glass account is required. Apple iCloud/Keychain services and
  explicit consent govern eligible credential mobility.
- App sharing, device mobility, and authentication kind are independent. A
  credential can be known to both apps while unavailable on the current device.
- Secure Enclave and user-presence-protected material remains device-bound and
  requires local setup. The package never substitutes weaker authentication.
- Endpoint metadata and app overlays refer to stable package-owned credential
  identity; secret material never enters endpoint or CloudKit metadata records.

# Project Brief — GlasSecretStore

## Vision
Shared Swift package providing unified credential identity, availability,
Keychain, Secure Enclave, and SSH host-trust operations for the **glas.sh** and
**glassdb** apps. It is the security substrate behind the Glass-family *Magic /
First Class* experience: define an SSH connection once, find it across supported
Apple devices, and connect with the least intervention compatible with honest
security.

## Goals
1. Single source of truth for Glass-family credential identity, kind,
   availability, storage, retrieval, rotation, and deletion
2. Explicit, independent policies for app sharing, device mobility, and
   authentication requirements
3. Secure Enclave P256 wrap/unwrap and device-bound availability support
4. Backward-compatible, collision-safe migration from legacy Keychain formats
5. Configuration-driven services for cross-app Keychain sharing and eligible
   Apple-protected credential mobility
6. Shared SSH host-trust storage without silently treating a synced endpoint as
   trusted on a new device
7. Clean public API surface for visionOS, macOS, iOS, and iPadOS consumers

## Consumers
- **glas.sh** — SSH terminal for Vision Pro, Mac, iPad, and iPhone
- **glassdb** — Database client for Vision Pro, Mac, iPad, and iPhone

## Non-Goals
- This package does NOT handle UI, networking, or SSH protocol logic
- This package does NOT own the neutral endpoint schema, CloudKit endpoint
  records, database overlays, terminal/workspace settings, or application UI
- Consumer apps own presentation and app-specific overlays, but must not create
  competing credential identities, availability catalogs, or Keychain policy
- Current `ThisDeviceOnly` storage must not be described as cross-device
  synchronization until the eligible mobility implementation and migrations pass

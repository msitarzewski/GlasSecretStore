# Project Brief — GlasSecretStore

## Vision
Shared Swift package providing unified Keychain and Secure Enclave operations for the **glas.sh** and **glassdb** apps. Extracted to eliminate duplicated secret-storage code across both apps.

## Goals
1. Single source of truth for SSH key storage, retrieval, and deletion
2. Secure Enclave P256 wrap/unwrap support
3. Backward-compatible migration from legacy Keychain formats (v0 → v1)
4. Configuration-driven service names for cross-app Keychain sharing
5. Clean public API surface suitable for both visionOS and macOS targets

## Consumers
- **glas.sh** — SSH client for visionOS/macOS
- **glassdb** — Database client for visionOS/macOS

## Non-Goals
- This package does NOT handle UI, networking, or SSH protocol logic
- No direct UserDefaults persistence of SSH key metadata (that's the consumer's job via `StoredSSHKey`)

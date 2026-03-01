// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GlasSecretStore",
    platforms: [
        .visionOS(.v2),
        .macOS(.v15)
    ],
    products: [
        .library(name: "GlasSecretStore", targets: ["GlasSecretStore"]),
    ],
    targets: [
        .target(name: "GlasSecretStore"),
        .testTarget(name: "GlasSecretStoreTests", dependencies: ["GlasSecretStore"]),
    ]
)

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TinyString",
    platforms: [
        .macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1),
        // Floor is set by Embedded Swift's own minimum on Apple platforms, NOT by
        // InlineArray's "26"-generation requirement — InlineTinyString gates that
        // separately with a conditional @available (see InlineTinyString.swift).
    ],
    products: [
        .library(name: "TinyString", targets: ["TinyString"]),
    ],
    dependencies: [
        // Doc-generation tooling only — not linked into TinyString itself, so this doesn't
        // change the "zero runtime dependencies" story for consumers of the library.
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "TinyString",
            swiftSettings: [.swiftLanguageMode(.v6)]
            // Deliberately no .enableExperimentalFeature("Embedded") here: Embedded-ness
            // is a per-build-graph property opted into via CLI flags/SDK selection scoped
            // to a single product (see TinyStringEmbeddedSmokeTest and the README), not a
            // manifest setting — setting it here would force the Testing-based test target
            // into Embedded mode too and break `swift test`.
        ),
        .executableTarget(
            name: "TinyStringEmbeddedSmokeTest", // Runs tests for Embedded systems where Swift Testing is not supported
            dependencies: ["TinyString"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "TinyStringTests",
            dependencies: ["TinyString"]
        ),
    ]
)

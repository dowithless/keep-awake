// swift-tools-version: 5.9
import PackageDescription

// The app is built by Xcode. This package runs the manager tests.
let package = Package(
    name: "KeepAwakeCore",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "KeepAwakeCore",
            path: "KeepAwake",
            exclude: ["KeepAwakeApp.swift", "Assets.xcassets"],
            sources: ["SleepAssertionManager.swift", "LoginItemManager.swift"]
        ),
        .testTarget(name: "KeepAwakeCoreTests", dependencies: ["KeepAwakeCore"], path: "Tests")
    ]
)

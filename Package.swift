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
            exclude: ["KeepAwakeApp.swift", "HelpWindowController.swift", "Assets.xcassets", "Localizable.xcstrings", "PrivacyInfo.xcprivacy"],
            sources: ["SleepAssertionManager.swift", "LoginItemManager.swift", "SystemSleepMonitor.swift", "L10n.swift"]
        ),
        .testTarget(name: "KeepAwakeCoreTests", dependencies: ["KeepAwakeCore"], path: "Tests")
    ]
)

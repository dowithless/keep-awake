# Keep Awake

English | [简体中文](README.zh-CN.md)

A native macOS menu bar utility that prevents idle sleep. No third-party dependencies, accounts, subscriptions, in-app purchases, or persistent helper processes.

The project is open source, with a one-time paid download planned for the Mac App Store. Self-built and App Store versions offer the same features. The app does not verify purchase receipts or initiate network connections. The App Store version is not yet available.

## Usage

- Left-click the coffee cup to toggle keep-awake mode. A filled cup means it is on; an outlined cup means it is off.
- Right-click or Control-click to open the native menu, which closes normally after selecting an item.
- “Keep Display Awake” is enabled by default. Turn it off to keep your Mac awake while allowing the display to sleep according to system settings. This option is disabled while keep-awake mode is off, and your preference is saved.
- Keep-awake mode is off every time the app launches. System sleep ends the current session; enable it again manually after waking. Locking the screen, starting the screen saver, or putting only the display to sleep does not end the session.
- “Launch at Login” is enabled only at your request, with its status managed by macOS. Quitting the app does not unregister the login item.
- “About & Help” shows the version, core capabilities, features, and limitations. Once public URLs are configured, “Privacy Policy” and “Contact Support” buttons open the corresponding pages in your browser. The app has no Dock icon or settings window.
- Supports English, Simplified Chinese, Traditional Chinese, Japanese, Korean, German, French, Spanish, Brazilian Portuguese, Russian, and Italian. It follows system or per-app language preferences, with English as the fallback.

Keep Awake prevents **idle sleep** only. It does not prevent manual sleep or screen locking, unlock your desktop, guarantee operation with the lid closed, or override system or organizational security policies.

## Build

Requires macOS 13 or later. The project has been verified with Xcode 26.3. Open `KeepAwake.xcodeproj` and select the `KeepAwake` scheme for development.

Build and launch locally with ad hoc signing, without a developer account:

```sh
xcodebuild -project KeepAwake.xcodeproj -scheme KeepAwake \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual build
open build/DerivedData/Build/Products/Release/KeepAwake.app
```

For personal signing, copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and enter your team settings. All three build configurations load this file automatically, and Git ignores it. For everyday use, move the app to Applications before enabling Launch at Login.

## Tests

```sh
bash Scripts/test.sh
python3 Scripts/verify-localizations.py
```

To further verify a built app:

```sh
python3 Scripts/verify-localizations.py --app build/DerivedData/Build/Products/Release/KeepAwake.app
python3 Scripts/verify-language-selection.py build/DerivedData/Build/Products/Release/KeepAwake.app
bash Scripts/verify-live-assertions.sh
```

Test caches are stored in `build/`. Unit tests inject mock power and login-item APIs. The live IOKit probe briefly acquires and releases its own assertions without putting the computer to sleep or logging out. See [VALIDATION.md](VALIDATION.md) for automated checks and manual acceptance steps.

## Code Structure

- `KeepAwakeApp.swift`: AppKit menu bar interface, menus, and action feedback.
- `SleepAssertionManager.swift`: Both IOKit assertion types, display preferences, failure rollback, and release retries.
- `SystemSleepMonitor.swift`: Ends the session on system sleep and retries failed cleanup only after waking.
- `LoginItemManager.swift`: Native login-item registration, unregistration, and system status checks.
- `HelpWindowController.swift`: A single-page native help window.
- `L10n.swift` and `Localizable.xcstrings`: App copy in 11 languages.

The app is built with Xcode; `Package.swift` is used only for core tests. After changing the interface, update the String Catalog and run the localization checks.

Icon assets are included. To regenerate them, run `xcrun swift -module-cache-path build/ModuleCache Scripts/GenerateAppIcon.swift`.

See the [release guide](docs/release/README.md) for App Store signing, release checks, and store metadata maintenance.

## Support and privacy

Report problems or feature requests through [GitHub Issues](https://github.com/dowithless/keep-awake/issues). For privacy requests, email [neo.dowithless@gmail.com](mailto:neo.dowithless@gmail.com). Public issues are visible to everyone; use email for private information.

Developer: Neo. Read the [Privacy Policy](docs/privacy/privacy-policy.en.md) ([简体中文](docs/privacy/privacy-policy.zh-Hans.md)) for local app behavior, support information and deletion requests.

## License

The source code is available under the [MIT License](LICENSE).

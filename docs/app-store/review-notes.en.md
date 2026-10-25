# App Review notes — draft

Keep Awake is a macOS menu bar utility. Its main experience is the cup icon in the menu bar; no Dock icon or main window appears on launch.

1. Locate the cup icon at the top of the screen. Left-click it to turn keep-awake mode on or off.
2. Right-click or Control-click the cup to open the native menu.
3. With Keep Awake on, toggle Keep Display Awake to independently allow/prevent idle display sleep.
4. The optional Launch at Login item is off until explicitly enabled by the user. macOS may require approval in System Settings. Launching at login does not automatically activate keep-awake mode.
5. System sleep ends the current session. After waking, the app remains running with keep-awake mode off.
6. About & Help opens a small native window containing help and an offline privacy statement. Public privacy/support buttons appear after the actual URLs are configured for the release.

Business model: paid App Store download, all features included. No subscriptions, IAP products, developer account or developer backend. The source is available separately for users to build. Both distributions offer the same features; the app has no purchase verification, license keys or developer login.

Power behavior: public IOKit power assertions prevent idle sleep only. The app does not simulate input, unlock the Mac, alter security settings, prevent manual sleep/locking or guarantee closed-lid operation.

Supported languages: English, Simplified Chinese, Traditional Chinese, Japanese, Korean, German, French, Spanish, Brazilian Portuguese, Russian, Italian. The app follows system/per-app language preferences with English fallback.

Before submitting: remove this document heading, confirm the final build and screenshots, verify live privacy/support URLs, and provide the actual reviewer contact details in App Store Connect. Do not describe unexecuted tests as passed.

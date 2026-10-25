# Keep Awake Privacy Policy — publication draft

Status: developer review only. Complete the operator, contact, effective date, support practices and website disclosures before publication. Code inventory date: 2026-10-25.

- Operator: [actual developer or legal entity]
- Privacy contact: [email address]
- Effective date: [publication effective date]

## App operation

Keep Awake is a local Mac menu bar utility that does not require an app account. The app does not transmit personal information, usage analytics, advertising identifiers or purchase records to a developer server. It currently has no advertising, third-party analytics SDKs, cloud sync or developer backend.

The app uses macOS power assertions and system sleep/wake notifications. It does not read screen contents, keyboard input, browsing history, file contents or location to perform this function.

## Local settings and diagnostics

The display-awake preference is stored on this Mac using UserDefaults. An active keep-awake session is not saved across launches. macOS manages login items; the app registers or unregisters only in response to user action and reads their current status for its menu.

Some operation failures may be written to local system logs. The app does not upload these logs. macOS log retention and any sharing of system diagnostics with Apple depend on system settings and Apple's policies. Quitting does not erase the saved preference or unregister a login item that you enabled. You can disable launch at login in the app or in System Settings.

## Purchases and Apple

Keep Awake is a paid Mac App Store download with no subscriptions or in-app purchases. Apple handles payment, downloads, redownloads and updates. The developer does not receive payment card details.

The app does not verify purchases or access transaction records. Apple's services are covered by [Apple's Privacy Policy](https://www.apple.com/legal/privacy/).

## Websites and support

Support and privacy links open in your default browser only when you select them. The final policy and website must describe any hosting logs, cookies and support information actually processed by those services.

If you contact support, you may voluntarily provide an email address, an issue description or diagnostic information. Before publication, the operator must specify the support channel, purposes, recipients, retention and deletion procedure. The app currently has no feedback-upload feature.

## Control and deletion

The app has no developer-operated user accounts or user database. Local settings can be reset by deleting the app's local preferences. Uninstalling does not guarantee that macOS removes all preferences or system logs. Contact the privacy address above about information voluntarily sent to support.

## Changes

Before introducing networking, analytics, crash reporting or other data practices, update this policy, the in-app statement and App Store privacy answers to match the released app.

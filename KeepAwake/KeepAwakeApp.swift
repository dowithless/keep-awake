import AppKit
import ServiceManagement

@main
struct KeepAwakeApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = KeepAwakeDelegate()
        application.delegate = delegate
        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}

@MainActor
final class KeepAwakeDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let manager = SleepAssertionManager()
    private let loginManager = LoginItemManager()
    private let purchaseManager = AppPurchaseManager()
    private var helpController: HelpWindowController?
    private var sleepMonitor: SystemSleepMonitor?
    private var statusItem: NSStatusItem?
    private let menu = NSMenu(title: "Keep Awake")
    private let purchaseItem = NSMenuItem(title: L10n.text("Verify App Store Purchase…"), action: #selector(verifyPurchase(_:)), keyEquivalent: "")
    private let enabledItem = NSMenuItem(title: L10n.text("Keep Awake"), action: #selector(toggleAwake(_:)), keyEquivalent: "")
    private let displayItem = NSMenuItem(title: L10n.text("Keep Display Awake"), action: #selector(toggleDisplay(_:)), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: L10n.text("Launch at Login"), action: #selector(toggleLoginItem(_:)), keyEquivalent: "")
    private let loginSettingsItem = NSMenuItem(title: L10n.text("Allow in System Settings…"), action: #selector(openLoginSettings(_:)), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu.autoenablesItems = false
        menu.delegate = self
        enabledItem.target = self
        displayItem.target = self
        menu.addItem(enabledItem)
        menu.addItem(displayItem)
        menu.addItem(.separator())
        loginItem.target = self
        loginSettingsItem.target = self
        menu.addItem(loginItem)
        menu.addItem(loginSettingsItem)
        menu.addItem(.separator())
        purchaseItem.target = self
        menu.addItem(purchaseItem)
        let helpItem = NSMenuItem(title: L10n.text("About & Help…"), action: #selector(showHelp(_:)), keyEquivalent: "")
        helpItem.target = self
        menu.addItem(helpItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: L10n.text("Quit Keep Awake"), action: #selector(quit(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        if let button = item.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updatePresentation()
        purchaseManager.onStateChange = { [weak self] in self?.updatePresentation() }
        Task { [weak self] in
            guard let self else { return }
            await purchaseManager.verify()
            updatePresentation()
        }
        sleepMonitor = SystemSleepMonitor(
            manager: manager,
            onStateChange: { [weak self] in self?.updatePresentation() },
            onWakeError: { [weak self] in self?.showErrorIfNeeded($0) }
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        sleepMonitor?.stop()
        for error in manager.releaseForTermination() {
            NSLog("Keep Awake: %@", error)
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        updatePresentation()
    }

    func menuDidClose(_ menu: NSMenu) {
        // Attach the menu only while tracking it, so the next left click remains
        // a direct toggle rather than opening the menu again.
        statusItem?.menu = nil
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApplication.shared.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            updatePresentation()
            statusItem?.menu = menu
            sender.performClick(nil)
        } else {
            toggleAwake(sender)
        }
    }

    @objc private func toggleAwake(_ sender: Any?) {
        guard manager.isEnabled || purchaseManager.state.allowsUse else {
            showErrorIfNeeded(purchaseMessage())
            return
        }
        let error = manager.setEnabled(!manager.isEnabled)
        updatePresentation()
        showErrorIfNeeded(error)
    }

    @objc private func toggleDisplay(_ sender: Any?) {
        guard manager.isEnabled else { return }
        let error = manager.setPreventDisplaySleep(!manager.preventDisplaySleep)
        updatePresentation()
        showErrorIfNeeded(error)
    }

    @objc private func quit(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }

    @objc private func toggleLoginItem(_ sender: Any?) {
        let result = loginManager.setEnabled(!loginManager.isRegistered)
        updatePresentation()
        switch result {
        case .success:
            break
        case .requiresApproval:
            menu.cancelTracking()
            DispatchQueue.main.async { [self] in
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = L10n.text("Permission Needed for Launch at Login")
                alert.informativeText = L10n.text("Allow Keep Awake in Login Items in System Settings. You can also turn off Launch at Login in the menu. Launching at login leaves Keep Awake off.")
                alert.addButton(withTitle: L10n.text("Open System Settings"))
                alert.addButton(withTitle: L10n.text("Later"))
                NSApplication.shared.activate(ignoringOtherApps: true)
                if alert.runModal() == .alertFirstButtonReturn {
                    loginManager.openSystemSettings()
                }
            }
        case .failure(let message):
            showErrorIfNeeded(message)
        }
    }

    @objc private func openLoginSettings(_ sender: Any?) {
        loginManager.openSystemSettings()
    }

    private func updatePresentation() {
        let state = manager.isEnabled ? L10n.text("On") : L10n.text("Off")
        let image = NSImage(
            systemSymbolName: manager.isEnabled ? "cup.and.saucer.fill" : "cup.and.saucer",
            accessibilityDescription: L10n.format("Keep Awake: %@", state)
        )
        image?.isTemplate = true
        statusItem?.button?.image = image
        statusItem?.button?.toolTip = L10n.format("Keep Awake: %@\nLeft-click to toggle; right-click or Control-click for the menu", state)
        statusItem?.button?.setAccessibilityLabel(L10n.format("Keep Awake: %@", state))
        statusItem?.button?.setAccessibilityHelp(L10n.text("Click to toggle Keep Awake; right-click or Control-click to open the menu"))
        purchaseItem.isHidden = purchaseManager.state.allowsUse
        purchaseItem.isEnabled = purchaseManager.state != .checking
        purchaseItem.title = purchaseManager.state == .checking ? L10n.text("Checking App Store Purchase…") : L10n.text("Verify App Store Purchase…")
        if !purchaseManager.state.allowsUse { statusItem?.button?.toolTip = purchaseMessage() }
        enabledItem.isEnabled = manager.isEnabled || purchaseManager.state.allowsUse
        enabledItem.state = manager.isEnabled ? .on : .off
        enabledItem.toolTip = L10n.text("Turns off when the Mac sleeps; turn it on again after waking")
        displayItem.state = manager.preventDisplaySleep ? .on : .off
        displayItem.isEnabled = manager.isEnabled
        displayItem.toolTip = manager.isEnabled ? nil : L10n.text("Turn on Keep Awake first. The checkmark shows your saved preference.")

        let loginStatus = loginManager.status
        switch loginStatus {
        case .enabled:
            loginItem.state = .on
        case .requiresApproval:
            loginItem.state = .mixed
        default:
            loginItem.state = .off
        }
        loginItem.title = loginStatus == .requiresApproval ? L10n.text("Launch at Login (Approval Needed)") : L10n.text("Launch at Login")
        loginItem.toolTip = loginStatus == .requiresApproval ? L10n.text("Approval is pending. Click to unregister, or allow it in System Settings.") : nil
        loginSettingsItem.isHidden = loginStatus != .requiresApproval
    }

    @objc private func showHelp(_ sender: Any?) {
        menu.cancelTracking()
        DispatchQueue.main.async { [self] in
            if helpController == nil { helpController = HelpWindowController() }
            helpController?.present()
        }
    }

    @objc private func verifyPurchase(_ sender: Any?) {
        Task { [weak self] in
            guard let self else { return }
            await purchaseManager.verify(refresh: true)
            updatePresentation()
            if !purchaseManager.state.allowsUse { showErrorIfNeeded(purchaseMessage()) }
        }
    }

    private func purchaseMessage() -> String {
        if purchaseManager.state == .checking { return L10n.text("Checking App Store Purchase…") }
        return L10n.text("The App Store purchase could not be verified. Connect to the internet and choose Verify App Store Purchase in the menu. If the problem continues, download Keep Awake again using the Apple Account that purchased it.")
    }

    private func showErrorIfNeeded(_ error: String?) {
        guard let error else { return }
        menu.cancelTracking()
        // Present after the native menu finishes handling the selection.
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = L10n.text("Unable to Complete Operation")
            alert.informativeText = error
            alert.addButton(withTitle: L10n.text("OK"))
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}

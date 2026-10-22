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
    private var sleepMonitor: SystemSleepMonitor?
    private var statusItem: NSStatusItem?
    private let menu = NSMenu(title: "Keep Awake")
    private let enabledItem = NSMenuItem(title: "保持唤醒", action: #selector(toggleAwake(_:)), keyEquivalent: "")
    private let displayItem = NSMenuItem(title: "同时保持屏幕常亮", action: #selector(toggleDisplay(_:)), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "登录时启动", action: #selector(toggleLoginItem(_:)), keyEquivalent: "")
    private let loginSettingsItem = NSMenuItem(title: "在系统设置中允许…", action: #selector(openLoginSettings(_:)), keyEquivalent: "")

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
        let quitItem = NSMenuItem(title: "退出 Keep Awake", action: #selector(quit(_:)), keyEquivalent: "q")
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
                alert.messageText = "需要系统允许登录时启动"
                alert.informativeText = "请在系统设置的登录项中允许 Keep Awake。你也可以在右键菜单中取消“登录时启动”。登录启动后，保持唤醒仍默认关闭。"
                alert.addButton(withTitle: "打开系统设置")
                alert.addButton(withTitle: "稍后")
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
        let state = manager.isEnabled ? "已开启" : "已关闭"
        let image = NSImage(
            systemSymbolName: manager.isEnabled ? "cup.and.saucer.fill" : "cup.and.saucer",
            accessibilityDescription: "Keep Awake：\(state)"
        )
        image?.isTemplate = true
        statusItem?.button?.image = image
        statusItem?.button?.toolTip = "Keep Awake：\(state)\n左键切换；右键或 Control＋点击打开菜单"
        statusItem?.button?.setAccessibilityLabel("Keep Awake：\(state)")
        statusItem?.button?.setAccessibilityHelp("点击切换保持唤醒；右键或 Control＋点击打开设置菜单")
        enabledItem.state = manager.isEnabled ? .on : .off
        enabledItem.toolTip = "系统睡眠时自动关闭；唤醒后需要重新开启"
        displayItem.state = manager.preventDisplaySleep ? .on : .off
        displayItem.isEnabled = manager.isEnabled
        displayItem.toolTip = manager.isEnabled ? nil : "先开启“保持唤醒”后可调整；当前勾选保留已保存的偏好"

        let loginStatus = loginManager.status
        switch loginStatus {
        case .enabled:
            loginItem.state = .on
        case .requiresApproval:
            loginItem.state = .mixed
        default:
            loginItem.state = .off
        }
        loginItem.title = loginStatus == .requiresApproval ? "登录时启动（待系统允许）" : "登录时启动"
        loginItem.toolTip = loginStatus == .requiresApproval ? "系统尚未允许；点击可取消注册，或在系统设置中允许" : nil
        loginSettingsItem.isHidden = loginStatus != .requiresApproval
    }

    private func showErrorIfNeeded(_ error: String?) {
        guard let error else { return }
        menu.cancelTracking()
        // Present after the native menu finishes handling the selection.
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "无法完成操作"
            alert.informativeText = error
            alert.addButton(withTitle: "好")
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}

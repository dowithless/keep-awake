import AppKit

/// A system sleep ends the current session. Screen sleep and session locking do not.
@MainActor
final class SystemSleepMonitor: NSObject {
    private let manager: SleepAssertionManager
    private let notificationCenter: NotificationCenter
    private let onStateChange: () -> Void
    private let onWakeError: (String) -> Void
    private var needsCleanupAfterWake = false

    init(
        manager: SleepAssertionManager,
        notificationCenter: NotificationCenter? = nil,
        onStateChange: @escaping () -> Void,
        onWakeError: @escaping (String) -> Void
    ) {
        self.manager = manager
        self.notificationCenter = notificationCenter ?? NSWorkspace.shared.notificationCenter
        self.onStateChange = onStateChange
        self.onWakeError = onWakeError
        super.init()
        self.notificationCenter.addObserver(
            self, selector: #selector(systemWillSleep(_:)),
            name: NSWorkspace.willSleepNotification, object: nil
        )
        self.notificationCenter.addObserver(
            self, selector: #selector(systemDidWake(_:)),
            name: NSWorkspace.didWakeNotification, object: nil
        )
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func stop() {
        notificationCenter.removeObserver(self)
        needsCleanupAfterWake = false
    }

    @objc private func systemWillSleep(_ notification: Notification) {
        // Run synchronously before suspension; never show a modal alert here.
        for error in manager.releaseForSystemSleep() {
            NSLog("Keep Awake: %@", error)
        }
        needsCleanupAfterWake = manager.isEnabled
        onStateChange()
    }

    @objc private func systemDidWake(_ notification: Notification) {
        // Successful cleanup stays off. Retry only assertions that failed to release.
        guard needsCleanupAfterWake else { return }
        needsCleanupAfterWake = false
        let errors = manager.releaseForSystemSleep()
        onStateChange()
        if !errors.isEmpty {
            onWakeError(errors.joined(separator: "\n")
                + "\n保持唤醒尚未完全关闭。请点击关闭重试，或退出应用。")
        }
    }
}

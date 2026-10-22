import AppKit
import IOKit.pwr_mgt

@main
struct KeepAwakeLiveProbe {
    @MainActor
    static func main() throws {
        let suite = "KeepAwakeLiveProbe.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let manager = SleepAssertionManager(defaults: defaults)
        defer {
            _ = manager.releaseForTermination()
            defaults.removePersistentDomain(forName: suite)
        }
        func require(_ condition: Bool, _ message: String) throws {
            if !condition { throw NSError(domain: "KeepAwakeLiveProbe", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
        }
        func checkNoError(_ error: String?) throws {
            try require(error == nil, error ?? "")
        }
        func present(_ id: IOPMAssertionID?) -> Bool {
            guard let id else { return false }
            guard let properties = IOPMAssertionCopyProperties(id) else { return false }
            _ = properties.takeRetainedValue()
            return true
        }
        func pmsetSnapshot(_ expectedCount: Int) throws {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            task.arguments = ["-g", "assertions"]
            let pipe = Pipe()
            task.standardOutput = pipe
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            let lines = String(decoding: data, as: UTF8.self).split(separator: "\n").filter { $0.contains("pid \(ProcessInfo.processInfo.processIdentifier)(") && $0.contains("Keep Awake:") }
            try require(task.terminationStatus == 0 && lines.count == expectedCount, "Unexpected pmset assertion count: \(lines.count)")
            print("PMSET: \(expectedCount) app assertions")
            for line in lines { print(line) }
        }
        try require(!manager.isEnabled, "Startup must be off")
        try checkNoError(manager.setEnabled(true))
        let systemID = manager.systemAssertionID
        let displayID = manager.displayAssertionID
        try require(present(systemID), "System assertion is not visible to IOKit")
        try require(present(displayID), "Display assertion is not visible to IOKit")
        print("PASS: live system/display assertions created and independently queried")
        try pmsetSnapshot(2)
        try checkNoError(manager.setPreventDisplaySleep(false))
        try require(present(systemID) && !present(displayID), "Display-only release failed")
        try require(manager.systemAssertionID == systemID, "System ID changed")
        print("PASS: display assertion released while same system assertion remains")
        try pmsetSnapshot(1)
        try checkNoError(manager.setEnabled(false))
        try require(!present(systemID) && !present(displayID), "Assertion remains after disabling")
        print("PASS: disabling releases all live assertions")
        try pmsetSnapshot(0)
        for _ in 0..<20 {
            try checkNoError(manager.setEnabled(true))
            try checkNoError(manager.setPreventDisplaySleep(true))
            try checkNoError(manager.setEnabled(false))
        }
        print("PASS: 20 live activation/display/disable cycles completed")
        let center = NotificationCenter()
        var sleepError: String?
        let monitor = SystemSleepMonitor(
            manager: manager, notificationCenter: center,
            onStateChange: {}, onWakeError: { sleepError = $0 }
        )
        defer { monitor.stop() }
        for displayAwake in [true, false] {
            try checkNoError(manager.setPreventDisplaySleep(displayAwake))
            try checkNoError(manager.setEnabled(true))
            let sleepSystemID = manager.systemAssertionID
            let sleepDisplayID = manager.displayAssertionID
            center.post(name: NSWorkspace.screensDidSleepNotification, object: nil)
            center.post(name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
            try require(present(sleepSystemID), "Screen/session notification ended the session")
            try require(!displayAwake || present(sleepDisplayID), "Screen notification released display assertion")
            center.post(name: NSWorkspace.willSleepNotification, object: nil)
            try require(!manager.isEnabled && !present(sleepSystemID) && !present(sleepDisplayID),
                        "System sleep notification did not release live assertions")
            center.post(name: NSWorkspace.didWakeNotification, object: nil)
            try require(!manager.isEnabled && sleepError == nil, "Wake restored a session or failed cleanup")
            try require(manager.prefersDisplayAwake == displayAwake, "Sleep changed display preference")
            try pmsetSnapshot(0)
        }
        print("PASS: simulated sleep notifications release real assertions in both display modes; wake stays off")
        try checkNoError(manager.setPreventDisplaySleep(true))
        try checkNoError(manager.setEnabled(true))
        let finalSystemID = manager.systemAssertionID
        let finalDisplayID = manager.displayAssertionID
        try require(manager.releaseForTermination().isEmpty, "Termination cleanup failed")
        try require(!present(finalSystemID) && !present(finalDisplayID), "Assertion remains after termination cleanup")
        print("PASS: termination cleanup releases both live assertions")
        try pmsetSnapshot(0)
    }
}

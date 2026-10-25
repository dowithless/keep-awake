import Combine
import Foundation
import IOKit.pwr_mgt

/// A small seam for deterministic failure tests; production always uses IOKit.
@MainActor
struct SleepAssertionAPI {
    var create: (CFString, CFString) -> (IOReturn, IOPMAssertionID)
    var release: (IOPMAssertionID) -> IOReturn

    static let live = SleepAssertionAPI(
        create: { type, name in
            var id = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                type, IOPMAssertionLevel(kIOPMAssertionLevelOn), name, &id
            )
            return (result, id)
        },
        release: { IOPMAssertionRelease($0) }
    )
}

@MainActor
final class SleepAssertionManager: ObservableObject {
    static let displayPreferenceKey = "preventDisplaySleep"

    @Published private(set) var prefersDisplayAwake: Bool
    @Published private(set) var systemAssertionID: IOPMAssertionID?
    @Published private(set) var displayAssertionID: IOPMAssertionID?

    // A display assertion also prevents system idle sleep. Any retained assertion
    // keeps the status icon on, including after unsuccessful cleanup.
    var isEnabled: Bool { systemAssertionID != nil || displayAssertionID != nil }

    // While running, show the effective display state. While off, show the saved
    // preference for the next activation. This also covers failed rollback.
    var preventDisplaySleep: Bool {
        isEnabled ? displayAssertionID != nil : prefersDisplayAwake
    }

    private let defaults: UserDefaults
    private let api: SleepAssertionAPI

    init(defaults: UserDefaults = .standard, api: SleepAssertionAPI? = nil) {
        self.defaults = defaults
        self.api = api ?? .live
        defaults.register(defaults: [Self.displayPreferenceKey: true])
        prefersDisplayAwake = defaults.bool(forKey: Self.displayPreferenceKey)
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) -> String? {
        if enabled {
            guard !isEnabled else { return nil }

            let (systemResult, systemID) = api.create(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                "Keep Awake: Prevent idle system sleep" as CFString
            )
            guard systemResult == kIOReturnSuccess else {
                return L10n.format("Could not turn on Keep Awake (%@). Keep Awake is off.", code(systemResult))
            }
            systemAssertionID = systemID

            if prefersDisplayAwake {
                let (displayResult, displayID) = createDisplayAssertion()
                guard displayResult == kIOReturnSuccess else {
                    let rollbackResult = releaseSystemAssertion()
                    if rollbackResult != kIOReturnSuccess {
                        return L10n.format("Could not keep the display awake (%@) or release the system assertion (%@). The Mac stays awake; the display may sleep. Turn off Keep Awake again or quit.", code(displayResult), code(rollbackResult))
                    }
                    return L10n.format("Could not keep the display awake (%@). Activation was rolled back. Keep Awake is off.", code(displayResult))
                }
                displayAssertionID = displayID
            }
            return nil
        }

        // Release display first: if that fails, keep the system assertion and
        // both visible options intact so the user can retry the same operation.
        let displayResult = releaseDisplayAssertion()
        guard displayResult == kIOReturnSuccess else {
            return L10n.format("Could not release the display assertion (%@). Keep Awake is still on. Retry or quit.", code(displayResult))
        }
        let systemResult = releaseSystemAssertion()
        guard systemResult == kIOReturnSuccess else {
            return L10n.format("Could not release the system assertion (%@). The Mac stays awake; the display may sleep. Turn off Keep Awake again or quit.", code(systemResult))
        }
        return nil
    }

    @discardableResult
    func setPreventDisplaySleep(_ prevent: Bool) -> String? {
        if isEnabled {
            if prevent && displayAssertionID == nil {
                let (result, id) = createDisplayAssertion()
                guard result == kIOReturnSuccess else {
                    return L10n.format("Could not keep the display awake (%@). The Mac stays awake. The display setting and saved preference are unchanged.", code(result))
                }
                displayAssertionID = id
            } else if !prevent {
                let result = releaseDisplayAssertion()
                guard result == kIOReturnSuccess else {
                    return L10n.format("Could not release the display assertion (%@). The display stays awake. Your preference is unchanged. Retry.", code(result))
                }
            }
        }

        prefersDisplayAwake = prevent
        defaults.set(prevent, forKey: Self.displayPreferenceKey)
        return nil
    }

    /// Attempt both releases even if one fails; process exit is the final cleanup.
    func releaseForTermination() -> [String] {
        releaseAssertions(context: "On quit")
    }

    /// End the temporary session without changing the saved display preference.
    /// Retain failed IDs so wake handling or a manual disable can retry cleanup.
    func releaseForSystemSleep() -> [String] {
        releaseAssertions(context: "On system sleep")
    }

    private func releaseAssertions(context: String) -> [String] {
        var errors: [String] = []
        let displayResult = releaseDisplayAssertion()
        if displayResult != kIOReturnSuccess {
            errors.append("\(context): could not release display assertion: \(code(displayResult))")
        }
        let systemResult = releaseSystemAssertion()
        if systemResult != kIOReturnSuccess {
            errors.append("\(context): could not release system assertion: \(code(systemResult))")
        }
        return errors
    }

    private func createDisplayAssertion() -> (IOReturn, IOPMAssertionID) {
        api.create(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            "Keep Awake: Prevent idle display sleep" as CFString
        )
    }

    private func releaseSystemAssertion() -> IOReturn {
        guard let id = systemAssertionID else { return kIOReturnSuccess }
        let result = api.release(id)
        if result == kIOReturnSuccess { systemAssertionID = nil }
        return result
    }

    private func releaseDisplayAssertion() -> IOReturn {
        guard let id = displayAssertionID else { return kIOReturnSuccess }
        let result = api.release(id)
        if result == kIOReturnSuccess { displayAssertionID = nil }
        return result
    }

    private func code(_ result: IOReturn) -> String {
        String(format: "0x%08X", UInt32(bitPattern: result))
    }
}

import AppKit
import IOKit.pwr_mgt
import XCTest
@testable import KeepAwakeCore

@MainActor
private final class FakeAssertions {
    var active: [IOPMAssertionID: String] = [:]
    var createCount = 0
    var failedCreates: Set<Int> = []
    var failedReleases: [IOPMAssertionID: Int] = [:]
    var releaseAttempts: [IOPMAssertionID] = []
    private var nextID: IOPMAssertionID = 1

    var api: SleepAssertionAPI {
        SleepAssertionAPI(create: { [self] type, _ in
            createCount += 1
            if failedCreates.contains(createCount) {
                // Failed API output must never be retained or released.
                return (kIOReturnError, 999)
            }
            let id = nextID
            nextID += 1
            active[id] = type as String
            return (kIOReturnSuccess, id)
        }, release: { [self] id in
            releaseAttempts.append(id)
            if let failures = failedReleases[id], failures > 0 {
                failedReleases[id] = failures - 1
                return kIOReturnError
            }
            guard active.removeValue(forKey: id) != nil else { return kIOReturnBadArgument }
            return kIOReturnSuccess
        })
    }
}

final class SleepAssertionManagerTests: XCTestCase {
    @MainActor
    private func withFixture(_ body: (SleepAssertionManager, FakeAssertions, UserDefaults) throws -> Void) rethrows {
        let suite = "KeepAwakeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let fake = FakeAssertions()
        let manager = SleepAssertionManager(defaults: defaults, api: fake.api)
        defer {
            fake.failedReleases.removeAll()
            _ = manager.releaseForTermination()
            defaults.removePersistentDomain(forName: suite)
        }
        try body(manager, fake, defaults)
    }

    @MainActor
    func testFirstLaunchIsOffWithDisplayPreferenceOn() async {
        withFixture { manager, fake, _ in
            XCTAssertFalse(manager.isEnabled)
            XCTAssertTrue(manager.preventDisplaySleep)
            XCTAssertTrue(manager.prefersDisplayAwake)
            XCTAssertEqual(fake.createCount, 0)
        }
    }

    @MainActor
    func testChangingPreferenceWhileOffCreatesNothingAndRestoresOnRelaunch() async {
        withFixture { manager, fake, defaults in
            XCTAssertNil(manager.setPreventDisplaySleep(false))
            XCTAssertFalse(manager.preventDisplaySleep)
            XCTAssertEqual(fake.createCount, 0)
            let relaunched = SleepAssertionManager(defaults: defaults, api: fake.api)
            XCTAssertFalse(relaunched.isEnabled)
            XCTAssertFalse(relaunched.preventDisplaySleep)
        }
    }

    @MainActor
    func testDefaultActivationCreatesBothAssertionTypesAndDisableReleasesBoth() async {
        withFixture { manager, fake, _ in
            XCTAssertNil(manager.setEnabled(true))
            XCTAssertTrue(manager.isEnabled)
            XCTAssertTrue(manager.preventDisplaySleep)
            XCTAssertEqual(Set(fake.active.values), Set([
                kIOPMAssertionTypePreventUserIdleSystemSleep as String,
                kIOPMAssertionTypePreventUserIdleDisplaySleep as String
            ]))
            XCTAssertNil(manager.setEnabled(false))
            XCTAssertFalse(manager.isEnabled)
            XCTAssertTrue(fake.active.isEmpty)
            XCTAssertTrue(manager.preventDisplaySleep)
        }
    }

    @MainActor
    func testRepeatedEnableAndDisableAreIdempotent() async {
        withFixture { manager, fake, _ in
            for _ in 0..<20 { XCTAssertNil(manager.setEnabled(true)) }
            XCTAssertEqual(fake.createCount, 2)
            for _ in 0..<20 { XCTAssertNil(manager.setEnabled(false)) }
            XCTAssertEqual(fake.releaseAttempts.count, 2)
            XCTAssertTrue(fake.active.isEmpty)
        }
    }

    @MainActor
    func testRapidCyclesDoNotLeakAssertions() async {
        withFixture { manager, fake, _ in
            for _ in 0..<100 {
                XCTAssertNil(manager.setEnabled(true))
                XCTAssertNil(manager.setPreventDisplaySleep(false))
                XCTAssertNil(manager.setPreventDisplaySleep(true))
                XCTAssertNil(manager.setEnabled(false))
            }
            XCTAssertTrue(fake.active.isEmpty)
            XCTAssertEqual(fake.createCount, fake.releaseAttempts.count)
        }
    }

    @MainActor
    func testSystemOnlyModeAndDisplayChangesPreserveSystemID() async throws {
        try withFixture { manager, fake, defaults in
            XCTAssertNil(manager.setPreventDisplaySleep(false))
            XCTAssertNil(manager.setEnabled(true))
            let systemID = try XCTUnwrap(manager.systemAssertionID)
            XCTAssertEqual(fake.active.count, 1)
            XCTAssertNil(manager.setPreventDisplaySleep(true))
            let displayID = try XCTUnwrap(manager.displayAssertionID)
            XCTAssertEqual(manager.systemAssertionID, systemID)
            XCTAssertTrue(defaults.bool(forKey: SleepAssertionManager.displayPreferenceKey))
            XCTAssertNil(manager.setPreventDisplaySleep(false))
            XCTAssertEqual(fake.releaseAttempts, [displayID])
            XCTAssertEqual(manager.systemAssertionID, systemID)
            XCTAssertNotNil(fake.active[systemID])
            XCTAssertFalse(defaults.bool(forKey: SleepAssertionManager.displayPreferenceKey))
        }
    }

    @MainActor
    func testFirstCreateFailureDoesNotAdoptFailedOutputID() async {
        withFixture { manager, fake, _ in
            fake.failedCreates = [1]
            XCTAssertNotNil(manager.setEnabled(true))
            XCTAssertFalse(manager.isEnabled)
            XCTAssertNil(manager.systemAssertionID)
            XCTAssertNil(manager.displayAssertionID)
            XCTAssertTrue(fake.active.isEmpty)
            XCTAssertTrue(fake.releaseAttempts.isEmpty)
        }
    }

    @MainActor
    func testSecondCreateFailureRollsBackSystemAndPreservesPreference() async {
        withFixture { manager, fake, defaults in
            fake.failedCreates = [2]
            XCTAssertNotNil(manager.setEnabled(true))
            XCTAssertFalse(manager.isEnabled)
            XCTAssertNil(manager.systemAssertionID)
            XCTAssertNil(manager.displayAssertionID)
            XCTAssertTrue(fake.active.isEmpty)
            XCTAssertEqual(fake.releaseAttempts, [1])
            XCTAssertTrue(manager.preventDisplaySleep)
            XCTAssertTrue(defaults.bool(forKey: SleepAssertionManager.displayPreferenceKey))
            XCTAssertNil(manager.setEnabled(true))
            XCTAssertEqual(fake.active.count, 2)
        }
    }

    @MainActor
    func testRuntimeDisplayCreateFailurePreservesSystemAndSavedPreference() async {
        withFixture { manager, fake, defaults in
            XCTAssertNil(manager.setPreventDisplaySleep(false))
            XCTAssertNil(manager.setEnabled(true))
            let systemID = manager.systemAssertionID
            fake.failedCreates = [2]
            XCTAssertNotNil(manager.setPreventDisplaySleep(true))
            XCTAssertTrue(manager.isEnabled)
            XCTAssertFalse(manager.preventDisplaySleep)
            XCTAssertFalse(defaults.bool(forKey: SleepAssertionManager.displayPreferenceKey))
            XCTAssertEqual(manager.systemAssertionID, systemID)
            XCTAssertEqual(fake.active.count, 1)
            XCTAssertTrue(fake.releaseAttempts.isEmpty)
        }
    }

    @MainActor
    func testDisplayReleaseFailurePreservesEffectiveStateAndPreference() async throws {
        try withFixture { manager, fake, defaults in
            XCTAssertNil(manager.setEnabled(true))
            let displayID = try XCTUnwrap(manager.displayAssertionID)
            fake.failedReleases[displayID] = 1
            XCTAssertNotNil(manager.setPreventDisplaySleep(false))
            XCTAssertTrue(manager.preventDisplaySleep)
            XCTAssertTrue(defaults.bool(forKey: SleepAssertionManager.displayPreferenceKey))
            XCTAssertEqual(fake.active.count, 2)
            XCTAssertEqual(manager.displayAssertionID, displayID)
            XCTAssertNil(manager.setPreventDisplaySleep(false))
            XCTAssertFalse(manager.preventDisplaySleep)
            XCTAssertEqual(fake.active.count, 1)
        }
    }

    @MainActor
    func testFailedDisableKeepsBothIDsAndCanRetry() async throws {
        try withFixture { manager, fake, _ in
            XCTAssertNil(manager.setEnabled(true))
            let displayID = try XCTUnwrap(manager.displayAssertionID)
            fake.failedReleases[displayID] = 1
            XCTAssertNotNil(manager.setEnabled(false))
            XCTAssertEqual(fake.active.count, 2)
            XCTAssertTrue(manager.isEnabled)
            XCTAssertEqual(fake.releaseAttempts, [displayID])
            XCTAssertNil(manager.setEnabled(false))
            XCTAssertTrue(fake.active.isEmpty)
            XCTAssertFalse(manager.isEnabled)
        }
    }

    @MainActor
    func testPartialDisableShowsActualDisplayStateAndKeepsSavedPreference() async throws {
        try withFixture { manager, fake, defaults in
            XCTAssertNil(manager.setEnabled(true))
            let systemID = try XCTUnwrap(manager.systemAssertionID)
            fake.failedReleases[systemID] = 1
            XCTAssertNotNil(manager.setEnabled(false))
            XCTAssertTrue(manager.isEnabled)
            XCTAssertFalse(manager.preventDisplaySleep)
            XCTAssertNil(manager.displayAssertionID)
            XCTAssertEqual(manager.systemAssertionID, systemID)
            XCTAssertTrue(defaults.bool(forKey: SleepAssertionManager.displayPreferenceKey))
            XCTAssertNil(manager.setEnabled(false))
            XCTAssertFalse(manager.isEnabled)
            XCTAssertTrue(manager.preventDisplaySleep)
            XCTAssertTrue(fake.active.isEmpty)
        }
    }

    @MainActor
    func testRollbackReleaseFailureKeepsIDAndAllowsCleanup() async {
        withFixture { manager, fake, defaults in
            fake.failedCreates = [2]
            fake.failedReleases[1] = 1
            XCTAssertNotNil(manager.setEnabled(true))
            XCTAssertTrue(manager.isEnabled)
            XCTAssertFalse(manager.preventDisplaySleep)
            XCTAssertEqual(manager.systemAssertionID, 1)
            XCTAssertEqual(fake.active.count, 1)
            XCTAssertTrue(defaults.bool(forKey: SleepAssertionManager.displayPreferenceKey))
            XCTAssertNil(manager.setEnabled(false))
            XCTAssertFalse(manager.isEnabled)
            XCTAssertTrue(fake.active.isEmpty)
        }
    }

    @MainActor
    func testRelaunchNeverRestoresMasterSwitch() async {
        withFixture { manager, fake, defaults in
            XCTAssertNil(manager.setEnabled(true))
            let relaunched = SleepAssertionManager(defaults: defaults, api: fake.api)
            XCTAssertFalse(relaunched.isEnabled)
            XCTAssertTrue(relaunched.preventDisplaySleep)
        }
    }

    @MainActor
    func testTerminationAttemptsBothReleasesEvenWhenDisplayReleaseFails() async throws {
        try withFixture { manager, fake, _ in
            XCTAssertNil(manager.setEnabled(true))
            let systemID = try XCTUnwrap(manager.systemAssertionID)
            let displayID = try XCTUnwrap(manager.displayAssertionID)
            fake.failedReleases[displayID] = 1
            XCTAssertEqual(manager.releaseForTermination().count, 1)
            XCTAssertEqual(fake.releaseAttempts, [displayID, systemID])
            XCTAssertNil(manager.systemAssertionID)
            XCTAssertEqual(manager.displayAssertionID, displayID)
            XCTAssertTrue(manager.isEnabled)
            XCTAssertTrue(manager.releaseForTermination().isEmpty)
            XCTAssertFalse(manager.isEnabled)
        }
    }

    @MainActor
    func testSystemSleepEndsSessionAndPreservesEitherDisplayPreference() async {
        for displayAwake in [true, false] {
            withFixture { manager, fake, defaults in
                let center = NotificationCenter()
                var changes = 0
                let monitor = SystemSleepMonitor(
                    manager: manager, notificationCenter: center,
                    onStateChange: { changes += 1 }, onWakeError: { XCTFail($0) }
                )
                defer { monitor.stop() }
                XCTAssertNil(manager.setPreventDisplaySleep(displayAwake))
                XCTAssertNil(manager.setEnabled(true))
                center.post(name: NSWorkspace.willSleepNotification, object: nil)
                XCTAssertFalse(manager.isEnabled)
                XCTAssertTrue(fake.active.isEmpty)
                XCTAssertEqual(changes, 1)
                XCTAssertEqual(manager.prefersDisplayAwake, displayAwake)
                XCTAssertEqual(defaults.bool(forKey: SleepAssertionManager.displayPreferenceKey), displayAwake)
                let creates = fake.createCount
                center.post(name: NSWorkspace.didWakeNotification, object: nil)
                XCTAssertFalse(manager.isEnabled)
                XCTAssertEqual(fake.createCount, creates)

                // The next session must be explicitly enabled and use the saved preference.
                XCTAssertNil(manager.setEnabled(true))
                XCTAssertEqual(manager.displayAssertionID != nil, displayAwake)
                center.post(name: NSWorkspace.didWakeNotification, object: nil)
                XCTAssertTrue(manager.isEnabled)
            }
        }
    }

    @MainActor
    func testScreenSleepAndInactiveSessionDoNotEndSession() async {
        withFixture { manager, fake, _ in
            let center = NotificationCenter()
            let monitor = SystemSleepMonitor(
                manager: manager, notificationCenter: center,
                onStateChange: { XCTFail("Unexpected state change") }, onWakeError: { XCTFail($0) }
            )
            defer { monitor.stop() }
            XCTAssertNil(manager.setEnabled(true))
            for name in [NSWorkspace.screensDidSleepNotification, NSWorkspace.screensDidWakeNotification,
                         NSWorkspace.sessionDidResignActiveNotification, NSWorkspace.didWakeNotification] {
                center.post(name: name, object: nil)
            }
            XCTAssertTrue(manager.isEnabled)
            XCTAssertEqual(fake.active.count, 2)
            XCTAssertTrue(fake.releaseAttempts.isEmpty)
        }
    }

    @MainActor
    func testSleepAndWakeWhileOffAndRepeatedSleepAreIdempotent() async {
        withFixture { manager, fake, _ in
            let center = NotificationCenter()
            let monitor = SystemSleepMonitor(
                manager: manager, notificationCenter: center,
                onStateChange: {}, onWakeError: { XCTFail($0) }
            )
            defer { monitor.stop() }
            center.post(name: NSWorkspace.willSleepNotification, object: nil)
            center.post(name: NSWorkspace.didWakeNotification, object: nil)
            XCTAssertTrue(fake.releaseAttempts.isEmpty)
            XCTAssertEqual(fake.createCount, 0)
            XCTAssertNil(manager.setEnabled(true))
            for _ in 0..<3 { center.post(name: NSWorkspace.willSleepNotification, object: nil) }
            center.post(name: NSWorkspace.didWakeNotification, object: nil)
            XCTAssertFalse(manager.isEnabled)
            XCTAssertEqual(fake.releaseAttempts.count, 2)
        }
    }

    @MainActor
    func testSleepAttemptsBothReleasesAndWakeRetriesOnlyFailedAssertion() async throws {
        for failDisplay in [true, false] {
            try withFixture { manager, fake, _ in
                let center = NotificationCenter()
                var changes = 0
                let monitor = SystemSleepMonitor(
                    manager: manager, notificationCenter: center,
                    onStateChange: { changes += 1 }, onWakeError: { XCTFail($0) }
                )
                defer { monitor.stop() }
                XCTAssertNil(manager.setEnabled(true))
                let systemID = try XCTUnwrap(manager.systemAssertionID)
                let displayID = try XCTUnwrap(manager.displayAssertionID)
                let failedID = failDisplay ? displayID : systemID
                fake.failedReleases[failedID] = 1
                center.post(name: NSWorkspace.willSleepNotification, object: nil)
                XCTAssertEqual(fake.releaseAttempts, [displayID, systemID])
                XCTAssertEqual(Set(fake.active.keys), [failedID])
                XCTAssertTrue(manager.isEnabled)
                center.post(name: NSWorkspace.didWakeNotification, object: nil)
                XCTAssertEqual(fake.releaseAttempts, [displayID, systemID, failedID])
                XCTAssertFalse(manager.isEnabled)
                XCTAssertTrue(fake.active.isEmpty)
                XCTAssertEqual(changes, 2)
                XCTAssertEqual(fake.createCount, 2)
            }
        }
    }

    @MainActor
    func testPersistentSleepCleanupFailureReportsAfterWakeAndAllowsManualRetry() async throws {
        try withFixture { manager, fake, _ in
            let center = NotificationCenter()
            var errors: [String] = []
            let monitor = SystemSleepMonitor(
                manager: manager, notificationCenter: center,
                onStateChange: {}, onWakeError: { errors.append($0) }
            )
            defer { monitor.stop() }
            XCTAssertNil(manager.setEnabled(true))
            let systemID = try XCTUnwrap(manager.systemAssertionID)
            let displayID = try XCTUnwrap(manager.displayAssertionID)
            fake.failedReleases = [systemID: 2, displayID: 2]
            center.post(name: NSWorkspace.willSleepNotification, object: nil)
            XCTAssertTrue(errors.isEmpty)
            center.post(name: NSWorkspace.didWakeNotification, object: nil)
            XCTAssertEqual(errors.count, 1)
            XCTAssertTrue(manager.isEnabled)
            XCTAssertNotNil(manager.systemAssertionID)
            XCTAssertNotNil(manager.displayAssertionID)
            XCTAssertTrue(manager.prefersDisplayAwake)
            XCTAssertNil(manager.setEnabled(false))
            XCTAssertFalse(manager.isEnabled)
        }
    }

    @MainActor
    func testManualCleanupBeforeWakeDoesNotReleaseAgain() async throws {
        try withFixture { manager, fake, _ in
            let center = NotificationCenter()
            let monitor = SystemSleepMonitor(
                manager: manager, notificationCenter: center,
                onStateChange: {}, onWakeError: { XCTFail($0) }
            )
            defer { monitor.stop() }
            XCTAssertNil(manager.setEnabled(true))
            fake.failedReleases[try XCTUnwrap(manager.systemAssertionID)] = 1
            center.post(name: NSWorkspace.willSleepNotification, object: nil)
            XCTAssertNil(manager.setEnabled(false))
            let attempts = fake.releaseAttempts
            center.post(name: NSWorkspace.didWakeNotification, object: nil)
            XCTAssertEqual(fake.releaseAttempts, attempts)
            XCTAssertFalse(manager.isEnabled)
        }
    }

    @MainActor
    func testStoppedMonitorIgnoresSleepAndWake() async {
        withFixture { manager, fake, _ in
            let center = NotificationCenter()
            let monitor = SystemSleepMonitor(
                manager: manager, notificationCenter: center,
                onStateChange: { XCTFail("Stopped monitor callback") }, onWakeError: { XCTFail($0) }
            )
            monitor.stop()
            XCTAssertNil(manager.setEnabled(true))
            center.post(name: NSWorkspace.willSleepNotification, object: nil)
            center.post(name: NSWorkspace.didWakeNotification, object: nil)
            XCTAssertTrue(manager.isEnabled)
            XCTAssertTrue(fake.releaseAttempts.isEmpty)
        }
    }
}

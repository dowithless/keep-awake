import Foundation
import ServiceManagement
import XCTest
@testable import KeepAwakeCore

@MainActor
private final class FakeLoginItem {
    var status: SMAppService.Status = .notRegistered
    var registeredStatus: SMAppService.Status = .enabled
    var unregisteredStatus: SMAppService.Status = .notRegistered
    var registerError: Error?
    var statusOnRegisterError: SMAppService.Status?
    var unregisterError: Error?
    var registerCalls = 0
    var unregisterCalls = 0
    var settingsCalls = 0

    var api: LoginItemAPI {
        LoginItemAPI(status: { [self] in status }, register: { [self] in
            registerCalls += 1
            if let registerError {
                if let statusOnRegisterError { status = statusOnRegisterError }
                throw registerError
            }
            status = registeredStatus
        }, unregister: { [self] in
            unregisterCalls += 1
            if let unregisterError { throw unregisterError }
            status = unregisteredStatus
        }, openSettings: { [self] in settingsCalls += 1 })
    }
}

final class LoginItemManagerTests: XCTestCase {
    @MainActor
    func testStartupOnlyReadsStatusWithoutRegistering() async {
        let fake = FakeLoginItem()
        let manager = LoginItemManager(api: fake.api)
        XCTAssertFalse(manager.isRegistered)
        XCTAssertEqual(manager.status, .notRegistered)
        XCTAssertEqual(fake.registerCalls, 0)
        XCTAssertEqual(fake.unregisterCalls, 0)
        XCTAssertEqual(fake.settingsCalls, 0)
    }

    @MainActor
    func testEnableAndDisableAreIdempotent() async {
        let fake = FakeLoginItem()
        let manager = LoginItemManager(api: fake.api)
        XCTAssertEqual(manager.setEnabled(true), .success)
        XCTAssertEqual(manager.setEnabled(true), .success)
        XCTAssertTrue(manager.isRegistered)
        XCTAssertEqual(fake.registerCalls, 1)
        XCTAssertEqual(manager.setEnabled(false), .success)
        XCTAssertEqual(manager.setEnabled(false), .success)
        XCTAssertFalse(manager.isRegistered)
        XCTAssertEqual(fake.unregisterCalls, 1)
    }

    @MainActor
    func testPendingApprovalIsDistinctFromEnabledAndCanBeCancelled() async {
        let fake = FakeLoginItem()
        fake.registeredStatus = .requiresApproval
        let manager = LoginItemManager(api: fake.api)
        XCTAssertEqual(manager.setEnabled(true), .requiresApproval)
        XCTAssertEqual(manager.status, .requiresApproval)
        XCTAssertTrue(manager.isRegistered)
        XCTAssertEqual(manager.setEnabled(true), .requiresApproval)
        XCTAssertEqual(fake.registerCalls, 1)
        XCTAssertEqual(fake.settingsCalls, 0)
        XCTAssertEqual(manager.setEnabled(false), .success)
        XCTAssertFalse(manager.isRegistered)
        XCTAssertEqual(fake.unregisterCalls, 1)
    }

    @MainActor
    func testExternalSystemChangesAreReflectedWithoutOverridingThem() async {
        let fake = FakeLoginItem()
        let manager = LoginItemManager(api: fake.api)
        fake.status = .enabled
        XCTAssertTrue(manager.isRegistered)
        fake.status = .requiresApproval
        XCTAssertEqual(manager.status, .requiresApproval)
        fake.status = .notRegistered
        XCTAssertFalse(manager.isRegistered)
        XCTAssertEqual(fake.registerCalls, 0)
        XCTAssertEqual(fake.unregisterCalls, 0)
    }

    @MainActor
    func testRegisterFailureDoesNotPretendEnabled() async {
        let fake = FakeLoginItem()
        fake.registerError = NSError(domain: "Test", code: 1)
        let manager = LoginItemManager(api: fake.api)
        guard case .failure = manager.setEnabled(true) else { return XCTFail("Expected registration failure") }
        XCTAssertFalse(manager.isRegistered)
        XCTAssertEqual(manager.status, .notRegistered)
    }

    @MainActor
    func testConsentDenialErrorUsesActualPendingApprovalState() async {
        let fake = FakeLoginItem()
        fake.registerError = NSError(domain: "Test", code: 3)
        fake.statusOnRegisterError = .requiresApproval
        let manager = LoginItemManager(api: fake.api)
        XCTAssertEqual(manager.setEnabled(true), .requiresApproval)
        XCTAssertEqual(manager.status, .requiresApproval)
        XCTAssertEqual(manager.setEnabled(false), .success)
        XCTAssertFalse(manager.isRegistered)
    }

    @MainActor
    func testUnregisterFailureKeepsSystemEnabledStateAndCanRetry() async {
        let fake = FakeLoginItem()
        fake.status = .enabled
        fake.unregisterError = NSError(domain: "Test", code: 2)
        let manager = LoginItemManager(api: fake.api)
        guard case .failure = manager.setEnabled(false) else { return XCTFail("Expected unregister failure") }
        XCTAssertEqual(manager.status, .enabled)
        fake.unregisterError = nil
        XCTAssertEqual(manager.setEnabled(false), .success)
        XCTAssertFalse(manager.isRegistered)
    }

    @MainActor
    func testNoThrowDoesNotOverrideUnconfirmedSystemState() async {
        let fake = FakeLoginItem()
        fake.registeredStatus = .notRegistered
        let manager = LoginItemManager(api: fake.api)
        guard case .failure = manager.setEnabled(true) else { return XCTFail("Expected unconfirmed registration") }
        XCTAssertFalse(manager.isRegistered)
        fake.status = .enabled
        fake.unregisteredStatus = .enabled
        guard case .failure = manager.setEnabled(false) else { return XCTFail("Expected unconfirmed unregistration") }
        XCTAssertTrue(manager.isRegistered)
    }

    @MainActor
    func testNotFoundIsOffAndCanAttemptRegistration() async {
        let fake = FakeLoginItem()
        fake.status = .notFound
        let manager = LoginItemManager(api: fake.api)
        XCTAssertFalse(manager.isRegistered)
        XCTAssertEqual(manager.setEnabled(false), .success)
        XCTAssertEqual(fake.unregisterCalls, 0)
        XCTAssertEqual(manager.setEnabled(true), .success)
        XCTAssertTrue(manager.isRegistered)
    }

    @MainActor
    func testSettingsOnlyOpenOnExplicitRequest() async {
        let fake = FakeLoginItem()
        let manager = LoginItemManager(api: fake.api)
        XCTAssertEqual(manager.setEnabled(true), .success)
        XCTAssertEqual(fake.settingsCalls, 0)
        manager.openSystemSettings()
        XCTAssertEqual(fake.settingsCalls, 1)
    }
}

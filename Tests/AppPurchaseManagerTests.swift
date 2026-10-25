import Foundation
import XCTest
@testable import KeepAwakeCore

final class AppPurchaseManagerTests: XCTestCase {
    private let bundleID = "neo.dowithless.KeepAwake"

    @MainActor
    func testLocalBuildNeverCallsStoreKit() async {
        var calls = 0
        let manager = AppPurchaseManager(requiresVerification: false, api: AppPurchaseAPI { _ in
            calls += 1
            throw URLError(.notConnectedToInternet)
        })
        await manager.verify()
        await manager.verify(refresh: true)
        XCTAssertEqual(calls, 0)
        XCTAssertEqual(manager.state, .notRequired)
        XCTAssertTrue(manager.state.allowsUse)
    }

    @MainActor
    func testStoreBuildRequiresVerificationBeforeUse() async {
        let manager = AppPurchaseManager(requiresVerification: true)
        XCTAssertEqual(manager.state, .checking)
        XCTAssertFalse(manager.state.allowsUse)
    }

    @MainActor
    func testProductionAndReviewSandboxTransactionsUnlockApp() async {
        for environment in [AppPurchaseRecord.Environment.production, .sandbox] {
            let manager = AppPurchaseManager(requiresVerification: true, expectedBundleID: bundleID, api: AppPurchaseAPI { [bundleID] _ in
                AppPurchaseRecord(isVerified: true, bundleID: bundleID, environment: environment)
            })
            await manager.verify()
            XCTAssertEqual(manager.state, .verified)
            XCTAssertTrue(manager.state.allowsUse)
        }
    }

    @MainActor
    func testInvalidSignatureBundleAndEnvironmentsDoNotUnlockApp() async {
        let records = [
            AppPurchaseRecord(isVerified: false, bundleID: bundleID, environment: .production),
            AppPurchaseRecord(isVerified: true, bundleID: "other.app", environment: .production),
            AppPurchaseRecord(isVerified: true, bundleID: bundleID, environment: .xcode),
            AppPurchaseRecord(isVerified: true, bundleID: bundleID, environment: .unknown)
        ]
        for record in records {
            let manager = AppPurchaseManager(requiresVerification: true, expectedBundleID: bundleID, api: AppPurchaseAPI { _ in record })
            await manager.verify()
            XCTAssertEqual(manager.state, .invalid)
            XCTAssertFalse(manager.state.allowsUse)
        }
    }

    @MainActor
    func testUnavailablePurchaseCanRecoverOnlyAfterSuccessfulVerification() async {
        var unavailable = true
        var refreshes: [Bool] = []
        let manager = AppPurchaseManager(requiresVerification: true, expectedBundleID: bundleID, api: AppPurchaseAPI { [bundleID] refresh in
            refreshes.append(refresh)
            if unavailable { throw URLError(.notConnectedToInternet) }
            return AppPurchaseRecord(isVerified: true, bundleID: bundleID, environment: .production)
        })
        await manager.verify()
        XCTAssertEqual(manager.state, .unavailable)
        XCTAssertFalse(manager.state.allowsUse)
        unavailable = false
        await manager.verify(refresh: true)
        XCTAssertEqual(manager.state, .verified)
        XCTAssertEqual(refreshes, [false, true])
    }

    @MainActor
    func testTransientFailureDoesNotInterruptAnAlreadyVerifiedSession() async {
        var offline = false
        let manager = AppPurchaseManager(requiresVerification: true, expectedBundleID: bundleID, api: AppPurchaseAPI { [bundleID] _ in
            if offline { throw URLError(.notConnectedToInternet) }
            return AppPurchaseRecord(isVerified: true, bundleID: bundleID, environment: .production)
        })
        await manager.verify()
        offline = true
        await manager.verify()
        XCTAssertEqual(manager.state, .verified)
        // No local paid flag: a fresh process must still obtain Apple's verified cache.
        let fresh = AppPurchaseManager(requiresVerification: true, expectedBundleID: bundleID, api: AppPurchaseAPI { _ in
            throw URLError(.notConnectedToInternet)
        })
        await fresh.verify()
        XCTAssertEqual(fresh.state, .unavailable)
    }

    @MainActor
    func testEmptyExpectedBundleCannotAuthorizeAnyTransaction() async {
        let manager = AppPurchaseManager(requiresVerification: true, expectedBundleID: "", api: AppPurchaseAPI { _ in
            AppPurchaseRecord(isVerified: true, bundleID: "", environment: .production)
        })
        await manager.verify()
        XCTAssertEqual(manager.state, .invalid)
    }

    @MainActor
    func testBuildConfigurationSelectsVerificationPolicy() async {
        let manager = AppPurchaseManager()
        #if APP_STORE
        XCTAssertEqual(manager.state, .checking)
        #else
        XCTAssertEqual(manager.state, .notRequired)
        #endif
    }
}

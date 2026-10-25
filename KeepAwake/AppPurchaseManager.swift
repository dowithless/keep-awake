import Foundation
import StoreKit

struct AppPurchaseRecord: Sendable {
    enum Environment: Sendable { case production, sandbox, xcode, unknown }
    let isVerified: Bool
    let bundleID: String
    let environment: Environment
}

@MainActor
struct AppPurchaseAPI {
    var load: (_ refresh: Bool) async throws -> AppPurchaseRecord

    static let live = AppPurchaseAPI { refresh in
        // shared uses Apple's cached transaction when available. Only the user's
        // explicit retry may refresh it (and potentially prompt for authentication).
        let result = try await (refresh ? AppTransaction.refresh() : AppTransaction.shared)
        let transaction: AppTransaction
        let isVerified: Bool
        switch result {
        case .verified(let value):
            transaction = value
            isVerified = true
        case .unverified(let value, _):
            transaction = value
            isVerified = false
        }
        let environment: AppPurchaseRecord.Environment
        switch transaction.environment {
        case .production: environment = .production
        case .sandbox: environment = .sandbox
        case .xcode: environment = .xcode
        default: environment = .unknown
        }
        return AppPurchaseRecord(isVerified: isVerified, bundleID: transaction.bundleID, environment: environment)
    }
}

/// Paid downloads have no IAP products or subscription state. No purchase data,
/// identifiers, or a forgeable "paid" boolean are persisted by this app.
@MainActor
final class AppPurchaseManager {
    enum State: Equatable {
        case notRequired, checking, verified, unavailable, invalid

        var allowsUse: Bool { self == .notRequired || self == .verified }
    }

    static var requiresVerification: Bool {
        #if APP_STORE
        true
        #else
        false
        #endif
    }

    private(set) var state: State { didSet { onStateChange?() } }
    var onStateChange: (() -> Void)?
    private let expectedBundleID: String
    private let api: AppPurchaseAPI
    private var isChecking = false

    init(
        requiresVerification: Bool? = nil,
        expectedBundleID: String = Bundle.main.bundleIdentifier ?? "",
        api: AppPurchaseAPI? = nil
    ) {
        state = (requiresVerification ?? Self.requiresVerification) ? .checking : .notRequired
        self.expectedBundleID = expectedBundleID
        self.api = api ?? .live
    }

    func verify(refresh: Bool = false) async {
        guard state != .notRequired, !isChecking else { return }
        isChecking = true
        defer { isChecking = false }
        let wasVerified = state == .verified
        if !wasVerified { state = .checking }
        do {
            let record = try await api.load(refresh)
            // Sandbox is required for TestFlight and App Review. Xcode test
            // transactions must never authorize an App Store distribution build.
            if record.isVerified, !expectedBundleID.isEmpty,
               record.bundleID == expectedBundleID,
               record.environment == .production || record.environment == .sandbox {
                state = .verified
            } else {
                state = .invalid
            }
        } catch {
            // A transient StoreKit failure must not revoke a transaction already
            // verified in this process. Across launches, trust Apple's cache only.
            state = wasVerified ? .verified : .unavailable
        }
    }
}

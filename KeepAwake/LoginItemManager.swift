import Foundation
import ServiceManagement

@MainActor
struct LoginItemAPI {
    var status: () -> SMAppService.Status
    var register: () throws -> Void
    var unregister: () throws -> Void
    var openSettings: () -> Void

    static let live = LoginItemAPI(
        status: { SMAppService.mainApp.status },
        register: { try SMAppService.mainApp.register() },
        unregister: { try SMAppService.mainApp.unregister() },
        openSettings: { SMAppService.openSystemSettingsLoginItems() }
    )
}

@MainActor
final class LoginItemManager {
    enum ChangeResult: Equatable {
        case success
        case requiresApproval
        case failure(String)
    }

    private let api: LoginItemAPI

    init(api: LoginItemAPI? = nil) {
        self.api = api ?? .live
    }

    // Always read the system, including changes made outside this app. Merely
    // launching the app or opening its menu must never register a login item.
    var status: SMAppService.Status { api.status() }

    var isRegistered: Bool {
        let current = status
        return current == .enabled || current == .requiresApproval
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) -> ChangeResult {
        let current = status
        do {
            if enabled {
                if current == .enabled { return .success }
                if current == .requiresApproval { return .requiresApproval }
                try api.register()
            } else {
                guard current == .enabled || current == .requiresApproval else { return .success }
                try api.unregister()
            }
        } catch {
            let actual = status
            if enabled && actual == .enabled { return .success }
            if enabled && actual == .requiresApproval { return .requiresApproval }
            if !enabled && (actual == .notRegistered || actual == .notFound) { return .success }
            let message = enabled
                ? L10n.format("Could not enable Launch at Login: %@\nThe menu shows the current system status.", error.localizedDescription)
                : L10n.format("Could not disable Launch at Login: %@\nThe menu shows the current system status.", error.localizedDescription)
            return .failure(message)
        }

        let updated = status
        if enabled {
            if updated == .enabled { return .success }
            if updated == .requiresApproval { return .requiresApproval }
            return .failure(L10n.text("macOS has not confirmed Launch at Login. Move the app to Applications, retry, and check Login Items in System Settings."))
        }
        if updated == .notRegistered || updated == .notFound { return .success }
        return .failure(L10n.text("macOS has not confirmed that Launch at Login is off. Retry or check Login Items in System Settings."))
    }

    func openSystemSettings() {
        api.openSettings()
    }
}

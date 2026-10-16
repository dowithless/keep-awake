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
            let action = enabled ? "开启" : "关闭"
            return .failure("未能\(action)登录时启动：\(error.localizedDescription)\n菜单将显示系统当前状态。")
        }

        let updated = status
        if enabled {
            if updated == .enabled { return .success }
            if updated == .requiresApproval { return .requiresApproval }
            return .failure("系统尚未确认登录时启动已开启。请将应用放到“应用程序”文件夹后重试，并检查系统的登录项设置。")
        }
        if updated == .notRegistered || updated == .notFound { return .success }
        return .failure("系统尚未确认登录时启动已关闭，请重试或在系统的登录项设置中检查。")
    }

    func openSystemSettings() {
        api.openSettings()
    }
}

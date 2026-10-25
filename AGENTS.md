# Repository Guidelines

## 项目结构与模块组织

- `KeepAwake/`：原生 AppKit 应用，包含菜单栏界面、防休眠断言管理、系统睡眠监听、登录项集成和帮助窗口。
- `KeepAwake/Assets.xcassets`：图标资源；`L10n.swift` 和 `Localizable.xcstrings`：11 种语言的应用文案。
- `KeepAwake.xcodeproj`：应用构建工程；`Package.swift` 仅用于核心代码测试。
- `Tests/`：Swift 单元测试；`Scripts/`：验证工具，其中 `Scripts/tests/` 存放 Python 回归测试。
- `Config/`：签名、权限和应用包配置；`docs/`：发布、App Store 和隐私文档；`VALIDATION.md`：自动检查与实机验收清单。
- 构建产物和缓存放在已被 Git 忽略的 `build/` 中。

## 构建、测试与本地开发

使用 macOS 和 Xcode 开发，最低支持 macOS 13；工程已使用 Xcode 26.3 验证。打开 `KeepAwake.xcodeproj`，选择 `KeepAwake` scheme。

无需开发者账户的本地临时签名构建与启动：

```sh
xcodebuild -project KeepAwake.xcodeproj -scheme KeepAwake \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual build
open build/DerivedData/Build/Products/Release/KeepAwake.app
```

- `bash Scripts/test.sh`：运行 Swift XCTest，缓存保存在仓库内。
- `python3 Scripts/verify-localizations.py`：检查文案键、翻译覆盖、占位符和换行。
- `python3 -m unittest discover -s Scripts/tests -v`：运行发布检查逻辑的回归测试。
- `bash Scripts/verify-live-assertions.sh`：验证真实 IOKit 断言和模拟睡眠通知。

## 代码风格与命名规范

沿用现有的四空格缩进。Swift 类型及对应文件名使用 `UpperCamelCase`，方法和属性使用 `lowerCamelCase`。保留界面和管理类的 `@MainActor` 隔离；系统 API 保持可注入，便于确定性测试。用户可见文案统一通过 `L10n` 获取，并同步更新 String Catalog。仓库尚未配置格式化或静态检查工具。

## 测试要求

Swift 测试使用 XCTest，文件命名为 `<Component>Tests.swift`，方法以 `test` 开头并描述预期行为；Python 测试使用 `unittest`，文件命名为 `test_*.py`。通过模拟 API 覆盖生命周期切换、失败回滚、清理重试和偏好持久化。当前未设置覆盖率数值门槛。原生界面、实际睡眠和登录启动按 `VALIDATION.md` 实机验收；文案变更须运行本地化检查。

## 提交与 Pull Request 规范

近期提交通常使用 `feat:`、`fix:` 或 `refactor:` 前缀，后接简短的动作描述。每次提交聚焦单一主题。PR 应说明行为变化、关联相关 issue、列出已完成的验证及待做的人工检查；涉及可见界面变化时附截图。

## 本地配置

将 `Config/Local.xcconfig.example` 复制为已被 Git 忽略的 `Config/Local.xcconfig`，填写个人签名设置。不要提交凭据或本地配置。App Store 分发流程见 `docs/release/README.md`。

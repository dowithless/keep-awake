# Keep Awake

macOS 原生菜单栏防休眠工具。无第三方依赖、账户、订阅、内购或常驻子进程。

项目计划开源，同时在 Mac App Store 提供一次性付费下载。自行构建与商店版本功能一致，应用不校验购买凭证、不主动联网。商店尚未上线。

## 使用

- 左键点击咖啡杯切换保持唤醒；实心杯表示开启，轮廓杯表示关闭。
- 右键或 Control＋点击打开系统原生菜单，选择后正常收起。
- “同时保持屏幕常亮”默认开启；取消后 Mac 保持唤醒，显示器可按系统策略关闭。总开关关闭时该选项置灰，偏好会保存。
- 每次启动默认关闭保持唤醒。系统睡眠结束当前会话，唤醒后需手动开启；锁屏、屏保和显示器休眠不结束会话。
- “登录时启动”由用户主动启用，状态以 macOS 为准；退出应用不注销登录项。
- “关于与帮助”提供版本、核心能力、产品特点和能力边界；配置公开地址后显示“隐私政策”和“联系支持”按钮，在浏览器中打开对应网页。无 Dock 图标或设置窗口。
- 支持英文、简繁中文、日文、韩文、德文、法文、西班牙文、巴西葡萄牙文、俄文、意大利文，跟随系统或单独 App 语言设置，英文回退。

仅阻止**空闲睡眠**，不阻止主动睡眠或锁屏，不解锁桌面，不保证合盖运行，不覆盖系统或组织安全策略。

## 构建

运行要求 macOS 13 或更新版本。当前工程使用 Xcode 26.3 验证。打开 `KeepAwake.xcodeproj`，选择 `KeepAwake` scheme 开发。

无需开发者账户的本地临时签名构建：

```sh
xcodebuild -project KeepAwake.xcodeproj -scheme KeepAwake \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual build
open build/DerivedData/Build/Products/Release/KeepAwake.app
```

需要个人签名时，将 `Config/Local.xcconfig.example` 复制为 `Config/Local.xcconfig`，填写自己的团队；该文件由三个构建配置自动加载，已被 Git 忽略。日常使用建议将应用放在“应用程序”后启用登录启动。

## 测试

```sh
bash Scripts/test.sh
python3 Scripts/verify-localizations.py
```

对构建产物进一步验证：

```sh
python3 Scripts/verify-localizations.py --app build/DerivedData/Build/Products/Release/KeepAwake.app
python3 Scripts/verify-language-selection.py build/DerivedData/Build/Products/Release/KeepAwake.app
bash Scripts/verify-live-assertions.sh
```

测试缓存位于 `build/`。单元测试注入模拟电源／登录项 API；真实 IOKit 探针短暂申请并释放自身断言，不让电脑睡眠或注销。检查范围与实机验收见 [VALIDATION.md](VALIDATION.md)。

## 代码结构

- `KeepAwakeApp.swift`：AppKit 菜单栏、菜单和操作反馈。
- `SleepAssertionManager.swift`：两类 IOKit 断言、屏幕偏好、失败回滚和释放重试。
- `SystemSleepMonitor.swift`：系统睡眠时结束会话，唤醒后仅重试失败清理。
- `LoginItemManager.swift`：原生登录项注册、注销与系统状态读取。
- `HelpWindowController.swift`：单页原生帮助窗口。
- `L10n.swift`、`Localizable.xcstrings`：应用内文案与 11 种语言。

应用由 Xcode 构建；`Package.swift` 仅用于核心测试。界面变更后同步更新 String Catalog 并运行本地化检查。

图标资源已包含；需要重新生成时运行 `xcrun swift -module-cache-path build/ModuleCache Scripts/GenerateAppIcon.swift`。

商店签名、发布检查与商店资料维护见 [发布说明](docs/release/README.md)。

## 许可证

源码采用 [MIT License](LICENSE)。

# Keep Awake

macOS 原生菜单栏防休眠工具。产品计划为 **Mac App Store 付费下载、一次购买、完整功能永久使用**；无订阅、无内购、无自建账户。当前代码和商店资料已准备，尚未提交或上线。

## 使用

- 左键点击菜单栏咖啡杯，直接切换“保持唤醒”。实心杯表示开启，轮廓杯表示关闭。
- 右键或 Control＋点击打开原生菜单。菜单使用系统默认的文字、勾号及间距，选择后正常收起。
- “同时保持屏幕常亮”默认勾选；取消后 Mac 继续保持唤醒，允许显示器按系统策略关闭。
- 总开关关闭时屏幕选项置灰；开启后恢复可操作。屏幕偏好会保存，每次启动总开关均关闭。
- “登录时启动”由用户主动启用；系统待允许时提供设置入口，也可再次点击取消注册。每次展开菜单读取系统实际状态。退出应用不注销登录项，取消登录项不退出应用。
- 实际系统睡眠结束本次保持唤醒；唤醒后保持关闭，需要时重新开启。屏幕偏好保留。单纯锁屏、屏保或显示器休眠不会结束会话。
- 无 Dock 图标。菜单新增“关于与帮助”，用小型原生窗口提供版本、帮助和离线隐私说明。
- 支持英文、简体中文、繁体中文、日文、韩文、德文、法文、西班牙文、葡萄牙文（巴西）、俄语、意大利文。跟随系统或系统为单独 App 选择的语言，英文回退。

## 构建

最低系统 **macOS 13.0**，Xcode 16 或更新版本；当前使用 Xcode 26.3。无第三方库、Homebrew 或常驻子进程。核心功能本机运行；商店购买校验可能通过 Apple 服务联网。

- **KeepAwake scheme / Debug 或 Release**：本地开发、预览及测试，无商店购买校验。
- **KeepAwake-AppStore scheme / AppStore 配置**：商店归档，编译 APP_STORE 并校验 Apple 应用交易。不要将普通 Release 当作商店正式构建上传。

本地临时签名构建：

```sh
xcodebuild -project KeepAwake.xcodeproj -scheme KeepAwake \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath build/LocalizationDerivedData \
  CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual build
ditto build/LocalizationDerivedData/Build/Products/Release/KeepAwake.app build/KeepAwake.app
open build/KeepAwake.app
```

日常使用建议将应用放在“应用程序”后启用登录启动。临时签名不等于 Mac App Store 分发签名；发布配置、构建变量及待补资料见 [发布准备入口](docs/release/README.md)。

## 测试

```sh
bash Scripts/test.sh
bash Scripts/test.sh -Xswiftc -DAPP_STORE
python3 -m unittest discover -s Scripts/tests -v
python3 Scripts/verify-localizations.py --app build/LocalizationDerivedData/Build/Products/Release/KeepAwake.app
python3 Scripts/verify-language-selection.py build/LocalizationDerivedData/Build/Products/Release/KeepAwake.app
bash Scripts/verify-live-assertions.sh
```

测试将 SwiftPM 缓存限制在 build/；--disable-sandbox 仅针对测试工具自身，不关闭应用的 App Sandbox。模拟测试不更改真实电源或登录项。真实 IOKit 探针短暂申请并释放自身断言，不让电脑睡眠或注销。

本地化检查核对源代码／String Catalog 的键、11 语言覆盖、格式占位符、换行、编译后的每个语言资源及商店文案长度。生成的商店文案仍需人工语言校对。

对实际分发签名的商店导出包：

```sh
python3 Scripts/check-release-readiness.py /absolute/path/KeepAwake.app
```

本地临时签名、缺少正式版权／隐私／支持网址时，发布检查会如实失败；这是预期的发布门槛，不影响开发构建使用。

## 实现

- `KeepAwakeApp.swift`：AppKit NSStatusItem + NSMenu，保留左右键行为与系统默认菜单视觉。
- `SleepAssertionManager.swift`：IOKit 系统／显示器断言，创建失败回滚、释放失败保留实际 ID、可重试。显示器单独切换不重建系统断言。
- `SystemSleepMonitor.swift`：系统睡眠前清理，唤醒后仅重试失败清理，不自动恢复会话。
- `LoginItemManager.swift`：SMAppService.mainApp，用户同意后注册，无额外后台服务或 LaunchAgent。
- `L10n.swift`、`Localizable.xcstrings`：54 组文案，11 种语言；包含错误、tooltip 和辅助功能说明。
- `AppPurchaseManager.swift`：App Store 构建使用 StoreKit AppTransaction 验证签名、Bundle ID、production/sandbox 环境。缺失／不可信交易不授权；仅用户主动重试会 refresh。应用不保存可伪造的“已付费”偏好或上传交易记录。使用 Apple 缓存支持离线验证，跨启动断网行为仍须商店实测。
- `HelpWindowController.swift`：原生帮助窗口；离线隐私说明始终可用，正式隐私／支持按钮由实际 HTTPS 构建变量启用。
- `Scripts/GenerateAppIcon.swift`：沿用原版无热气的 `cup.and.saucer.fill` 咖啡杯与茶碟，搭配浅色圆角背景，生成全部 macOS 尺寸。菜单栏继续使用原有系统单色符号及轮廓／实心两态。

重新生成图标：`xcrun swift -module-cache-path build/ModuleCache Scripts/GenerateAppIcon.swift`。

修改界面文案时更新 String Catalog，再运行 `python3 Scripts/prepare-store-materials.py` 可重新生成商店描述草案；该命令会覆盖 localizations.json，手工校对后应保留修改或将其移到生成器。

## 限制与验收

阻止的是系统／显示器的空闲睡眠。不会阻止主动睡眠或主动锁屏，不解锁桌面，不保证合盖继续运行，不覆盖低电量、企业策略或系统强制休眠。不监测 Codex 任务，不承诺任务结束后自动关闭。

“屏幕常亮”使用 PreventUserIdleDisplaySleep，预期也抑制自动屏保；实际屏保、自动锁屏及系统安全策略需目标设备实测。其他应用的断言和自动化输入也可能阻止空闲，需通过自身 PID 和 IOKit 断言判断效果。

逐项结果见 [VALIDATION.md](VALIDATION.md)。系统睡眠、登录启动、菜单视觉、不同系统／硬件、商店交易与截图的待验收清单见 [发布准备入口](docs/release/README.md)。

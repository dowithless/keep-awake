# 隐私申报依据

核对日期：2026-10-25。以下描述当前代码，最终申报应对照正式构建、实际支持渠道与 App Store Connect 问卷复核。

| 信息／功能 | 使用位置 | 是否上传开发者 | 建议申报依据 |
| --- | --- | --- | --- |
| 屏幕常亮偏好 | SleepAssertionManager / UserDefaults | 否 | 仅本机设置 |
| 登录项状态及操作 | LoginItemManager / SMAppService | 否 | macOS 管理；用户主动启用 |
| 系统睡眠／唤醒事件 | SystemSleepMonitor / NSWorkspace | 否 | 仅用于结束会话与清理断言 |
| 电源断言及错误码 | IOKit 管理类、本机系统日志 | 否 | 无日志上传模块 |
| 支持信息 | 用户选择打开的网站或自行联系 | 取决于最终渠道 | 发布前补齐网站与支持处理说明 |

商店隐私标签建议：如果最终版本维持以上行为，可按“Data Not Collected／未收集数据”准备。不等于 Apple 或用户另行打开的支持网站完全不处理数据。正式支持渠道若接收信息，应按 Apple 的具体披露定义判断是否需申报，不能直接沿用本表结论。

随包提供 PrivacyInfo.xcprivacy：tracking=false，无 collected data；UserDefaults 使用原因 CA92.1（仅应用自身设置）。Apple 的 required-reason API 规则列明的平台不包括原生 macOS；这里主动记录真实使用，并不把此项误写成 macOS 特有的拒审原因。

应用不校验购买凭证，也不访问交易记录。公开政策链接应出现在商店资料及应用内。应用内帮助窗口提供 11 种语言的离线行为说明；正式隐私网站的主体、联系人和支持流程尚待开发者确定。完整政策目前准备简体中文和英文草案，其他语言的政策网页翻译可后续补充。

核对来源：

- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [App Review Guidelines 5.1](https://developer.apple.com/app-store/review/guidelines/#privacy)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

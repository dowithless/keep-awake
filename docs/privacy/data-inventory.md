# 隐私申报依据

核对日期：2026-10-26。以下描述当前代码、已上传的 1.0（1）构建及已确定的支持渠道；正式申报仍需对照 App Store Connect 问卷复核。

| 信息／功能 | 使用位置 | 是否上传开发者 | 建议申报依据 |
| --- | --- | --- | --- |
| 屏幕常亮偏好 | SleepAssertionManager / UserDefaults | 否 | 仅本机设置 |
| 登录项状态及操作 | LoginItemManager / SMAppService | 否 | macOS 管理；用户主动启用 |
| 系统睡眠／唤醒事件 | SystemSleepMonitor / NSWorkspace | 否 | 仅用于结束会话与清理断言 |
| 电源断言及错误码 | IOKit 管理类、本机系统日志 | 否 | 无日志上传模块 |
| 支持信息 | 用户主动访问 GitHub、发布 Issue 或发送邮件 | 用户主动提供时可收到 | 公开内容、Gmail 邮件与平台处理已在正式政策说明；应用自身不上传反馈 |

商店隐私标签建议：如果最终版本维持以上行为，可按“Data Not Collected／未收集数据”准备。不等于 Apple 或用户另行打开的支持网站完全不处理数据。正式支持渠道若接收信息，应按 Apple 的具体披露定义判断是否需申报，不能直接沿用本表结论。

随包提供 PrivacyInfo.xcprivacy：tracking=false，无 collected data；UserDefaults 使用原因 CA92.1（仅应用自身设置）。Apple 的 required-reason API 规则列明的平台不包括原生 macOS；这里主动记录真实使用，并不把此项误写成 macOS 特有的拒审原因。

应用不校验购买凭证，也不访问交易记录。开发者已确认公开名称 Neo、隐私联系邮箱 neo.dowithless@gmail.com，并于 2026-10-25 发布正式[中文政策](privacy-policy.zh-Hans.md)和[英文政策](privacy-policy.en.md)。正文在公开 GitHub 页面维护；已保存商店中英文政策网址，已上传构建通过帮助窗口打开英文政策及中文互链。仓库首页是支持页，提供 GitHub Issues 和隐私联系邮箱；其他语言的政策翻译可后续补充。

2026-10-26 复核：Xcode 最终导出包的发布检查及 Apple 安装包证书链验证通过。后台“不收集数据”的申报已由开发者发布并核对；申报发布与政策文件公开是两个独立状态。

核对来源：

- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [App Review Guidelines 5.1](https://developer.apple.com/app-store/review/guidelines/#privacy)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

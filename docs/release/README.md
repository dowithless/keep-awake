# 商店发布

Keep Awake 保留 Mac App Store 一次性付费下载。自行构建与商店版本使用相同功能代码，无应用内购买校验、订阅或内购。当前未提交或上线。

## 构建配置

- `KeepAwake` scheme：Debug 调试，Release 本地构建。
- `KeepAwake-AppStore` scheme：Run／Archive 使用 AppStore 配置；Run 不附加调试器。该配置标识商店分发，并禁用调试权限注入。
- 三种配置均启用 App Sandbox 和 Hardened Runtime。

复制 `Config/Local.xcconfig.example` 为被 Git 忽略的 `Config/Local.xcconfig`，填写：

| 变量 | 内容 |
| --- | --- |
| DEVELOPMENT_TEAM | 自己的 Apple 开发者团队 |
| KEEP_AWAKE_COPYRIGHT | 实际版权主体与年份 |
| KEEP_AWAKE_PRIVACY_URL | 正式 HTTPS 隐私政策页 |
| KEEP_AWAKE_SUPPORT_URL | 正式 HTTPS 支持页 |

xcconfig 中 HTTPS 地址使用 `https:/$()/domain/path`，避免双斜线被解析为注释。也可通过 Xcode 或命令行覆盖构建变量。当前 Bundle ID 为 `neo.dowithless.KeepAwake`；修改后应与签名及商店记录一致。应用仅在配置了有效 HTTPS 地址时显示对应按钮。隐私政策正文只在公开页面维护，应用通过按钮在浏览器中打开该页面。源码、支持入口及正式中英文隐私政策已公开于 https://github.com/dowithless/keep-awake；本机被忽略的 `Config/Local.xcconfig` 已为首次上传配置真实网址与签名团队。

`Config/Info.plist` 已声明工具类分类 `public.app-category.utilities`，以及 `ITSAppUsesNonExemptEncryption=false`。当前应用不实现非豁免加密；后续引入相关功能时需重新核对声明。

```sh
xcodebuild -project KeepAwake.xcodeproj -scheme KeepAwake-AppStore \
  -configuration AppStore -destination 'generic/platform=macOS' \
  -archivePath build/KeepAwake.xcarchive archive
```

在 Xcode Organizer 中使用 Mac App Store Connect 分发流程。对正式导出包执行：

```sh
python3 -m unittest discover -s Scripts/tests -v
python3 Scripts/check-release-readiness.py /absolute/path/KeepAwake.app
```

检查包含商店配置标识、版权、网址格式、Apple 信任的商店分发签名、团队、沙盒、禁止调试权限、编译语言资源和商店文案。临时签名、开发签名及 Developer ID 签名不能通过该商店检查；它们不影响普通本地开发。

## 首次上传记录

2026-10-25 已通过 Xcode Organizer 上传 **1.0（构建 1）**，2026-10-26 复核最终导出包通过发布检查及 Apple 安装包签名链验证，发布检查回归测试 11 项通过。构建包含 Intel 与 Apple Silicon，最低支持 macOS 13。

- 归档：`build/KeepAwake-AppStore-1.0-1-final.xcarchive`。
- Xcode 最终导出包：`build/app-store/exports/KeepAwake-1.0-1/KeepAwake.pkg`。
- 已展开的最终应用：`build/app-store/expanded-1.0-1/neo.dowithless.KeepAwake.pkg/Payload/KeepAwake.app`。
- [上传成功凭证](../../build/app-store/evidence/xcode-upload-complete.png)。构建及凭证均被 Git 忽略。

签名检查针对 Xcode **正式分发导出后的应用**，分发流程会补齐签名信息；不要将中间归档的检查结果当作最终导出包结果。2026-10-26 已将构建 1.0（1）关联到版本页并重新载入核对；当前未提交审核。实时待办见[中文验收记录](../app-store/zh-Hans-baseline.md)。

## 资料维护

- [商店文案](../app-store/localizations.json)：11 种语言已按中文基准保存并重新载入核对；直接编辑，独立于应用 String Catalog。[验收记录](../app-store/localizations.md)。
- [自然搜索与命名草案](../app-store/discovery-plan.md)：功能型名称、11 语言标题与关键词、截图和上线后验证方案；后台当前名称以中文验收记录和各本地化保存记录为准。
- [定价](../app-store/pricing-policy.md)与[价目表](../app-store/pricing.csv)：2026-10-26 已保存并重新载入核对；中国大陆 ¥1 为基准，其余地区自动换算，供应范围为全部 175 个国家或地区。
- [审核说明](../app-store/review-notes.en.md)与[截图清单](../app-store/screenshots.md)。
- [隐私说明](../privacy/)：正式中英文政策、公开联系方式和数据处理依据；政策文件已发布，商店“不收集数据”声明已由开发者发布，2026-10-26 已核对。

## 发布前完成

- [x] 源码采用 [MIT License](../../LICENSE)。
- [x] 商店版权、隐私联系方式与正式支持／隐私网页。
- [x] 开发者账户、Bundle ID、商店记录、正式分发签名及首次上传。
- [x] 在版本页面关联已上传构建并保存。
- [x] 11 种语言的产品资料与隐私网址已保存并重新载入核对。
- [x] 价格和销售地区已保存并重新载入核对。
- [x] 商店“不收集数据”声明已由开发者发布并核对。
- [ ] 付费协议、银行与税务资料、地区合规资料；账户凭据不进入仓库。
- [ ] [实机验收](../../VALIDATION.md)、各语言人工校对、真实截图及 TestFlight 安装／更新。
- [ ] 分类、年龄分级、隐私标签与商店要求按最终发布内容核对。

本地检查通过不代表网页在线、后台资料、价格或审核已完成。

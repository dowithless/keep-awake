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

xcconfig 中 HTTPS 地址使用 `https:/$()/domain/path`，避免双斜线被解析为注释。也可通过 Xcode 或命令行覆盖构建变量。当前 Bundle ID 为 `neo.dowithless.KeepAwake`；修改后应与签名及商店记录一致。应用仅在配置了有效 HTTPS 地址时显示对应按钮。隐私政策正文只在公开页面维护，应用通过按钮在浏览器中打开该页面。公开网址待仓库上传 GitHub 后填写。

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

## 资料维护

- [商店文案](../app-store/localizations.json)：直接编辑，独立于应用 String Catalog，不再由脚本覆盖。
- [定价](../app-store/pricing-policy.md)与[参考价目表](../app-store/pricing.csv)：草案，实际价格与销售地区以后台核对为准。
- [审核说明](../app-store/review-notes.en.md)与[截图清单](../app-store/screenshots.md)。
- [隐私说明](../privacy/)：发布前补齐主体、联系方式和网站实际行为。

## 发布前完成

- [x] 源码采用 [MIT License](../../LICENSE)。
- [ ] 商店版权主体、隐私联系方式与正式支持／隐私网页。
- [ ] 开发者账户、Bundle ID、商店记录、正式签名。
- [ ] 付费协议、银行与税务资料、价格和销售地区；账户凭据不进入仓库。
- [ ] [实机验收](../../VALIDATION.md)、各语言人工校对、真实截图及 TestFlight 安装／更新。
- [ ] 分类、年龄分级、隐私标签与商店要求按最终发布内容核对。

本地检查通过不代表网页在线、后台资料、价格或审核已完成。

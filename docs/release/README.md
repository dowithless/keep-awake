# 发布准备入口

状态：本地实现和资料草案。尚未上传、提交审核或发布；开发者账户、正式签名和后台价格未由本任务配置。

## 已准备的材料

- `docs/app-store/localizations.json`：11 种语言的名称、副标题、关键词、描述草案；带 App Store locale 映射。
- `docs/app-store/pricing-policy.md`、`pricing.csv`：定价规则及重点地区参考价。
- `docs/app-store/review-notes.en.md`：英文审核操作说明。
- `docs/app-store/screenshots.md`：实际截图采集清单及规格；截图尚未采集。
- `docs/privacy/`：中英文完整政策草案与数据清单；应用内另含 11 语言离线隐私说明。
- `KeepAwake/PrivacyInfo.xcprivacy`：当前隐私行为声明。

## 需要开发者提供／完成

- [ ] 最终开发者／法律主体名称及版权文字。
- [ ] 隐私联系邮箱；实际支持渠道、保留期限和删除流程。
- [ ] 已公开的 HTTPS 隐私政策页及支持页；政策草案须先补齐主体信息。页面可用静态托管，不需要业务服务器。
- [ ] Apple Developer 有效资格、实际 Team ID、App ID、macOS 应用记录及名称可用性。
- [ ] 由账户持有人完成 Paid Apps Agreement、银行和税务资料；不要把银行资料或凭据写进仓库。
- [ ] 确认分类（建议 Utilities／工具）、年龄分级问卷、出口合规及可访问性标签均与最终产品一致。
- [ ] 按销售地区核对适用的后台资料，如欧盟 trader 身份及联系信息、中国大陆等地区要求；按原生 macOS 和实际功能判断，不直接套用其他平台的要求。
- [ ] 全部目标 storefront 的价格档位、生效日期、销售可用性及用户价／proceeds 复核。
- [ ] 原生 UI 实机验收、语言校对、实际截图及 TestFlight 分发验证。

## 构建与签名

共享 scheme `KeepAwake`：Debug 调试，Release 本地分发，均不做商店购买校验。
共享 scheme `KeepAwake-AppStore`：Archive/Run 使用 **AppStore** 配置，编译 `APP_STORE`，必须通过 Apple 原生交易校验才能开始防休眠会话。Run 不附加调试器，以兼容商店配置禁用调试权限的要求；日常调试使用普通 `KeepAwake` scheme。不要用普通 Release 归档上传商店。该配置允许 Apple 签名的 production/sandbox 交易，拒绝 Xcode 测试交易、未知环境、签名无效和 bundle ID 不匹配。

在 Xcode 的 Signing & Capabilities 选择实际开发者团队。最终 Bundle ID 目前为 `neo.dowithless.KeepAwake`；如需修改，必须与后台记录、签名一致。代码校验读取当前 Bundle ID，不硬编码旧 ID。

通过 Xcode User-Defined Build Settings 或私有的 xcconfig 提供以下变量，也可在命令行作为 xcodebuild 参数传入：

| 变量 | 要填写的内容 |
| --- | --- |
| KEEP_AWAKE_COPYRIGHT | 实际版权年及权利主体 |
| KEEP_AWAKE_PRIVACY_URL | 正式 HTTPS 隐私政策页 |
| KEEP_AWAKE_SUPPORT_URL | 正式 HTTPS 支持页 |

URL 和版权默认留空，避免编造主体／无效链接。应用在本地可查看离线隐私说明；外部隐私／支持按钮仅在配置 HTTPS 地址后出现。发布检查会将这些空值视为阻塞项。

示例归档命令（由开发者填写实际签名及上述变量后运行）：

```sh
xcodebuild -project KeepAwake.xcodeproj -scheme KeepAwake-AppStore \
  -configuration AppStore -destination 'generic/platform=macOS' \
  -archivePath build/KeepAwake.xcarchive archive
```

在 Organizer 选择对应 Mac App Store Connect 的导出／分发流程。Developer ID 公证用于商店外分发，不应当作 Mac App Store 发布签名的替代流程。此任务的本机临时签名构建不是可上传的正式分发包。

对正式导出 app 执行：

```sh
python3 Scripts/check-release-readiness.py /absolute/path/KeepAwake.app
```

脚本核对构建配置标识、实际 URL 格式、版权、签名、团队、沙盒、调试权限及 11 语言资源。签名必须使用 Apple 信任的 App Store 分发证书；Developer ID、开发证书及临时签名均不能通过。脚本通过也不等于后台协议、实时 URL、截图、定价或审核已完成。

## 购买校验验收

- [ ] TestFlight／商店沙盒中有合法 Apple 签名的交易后可正常开启；无需内购商品或自建登录。
- [ ] 已成功验证的用户在断网重启后仍能通过 Apple 缓存的验证交易使用。当前仅模拟测试，不保证系统缓存条件；实际清空／缺失缓存需联网恢复。
- [ ] 缺少购买凭证或 StoreKit 不可用时保持总开关关闭，菜单有重试入口，可退出、查看帮助。
- [ ] 主动重试可触发 Apple 身份认证并恢复使用；应用不自动循环弹出认证窗口。
- [ ] Bundle ID 不匹配、签名不可信、Xcode 测试交易不会授权商店构建。
- [ ] Apple 服务暂时异常不撤销同一运行进程已验证的状态，不要求每次点开关都联网。
- [ ] 测试重新下载、更新、多台 Mac 使用同一购买账户的行为。

## 功能与语言验收

- [ ] 每种语言检查菜单、tooltip、辅助功能说明、系统允许弹窗和错误提示；完整政策需人工校对后再发布。
- [ ] 首次启动总开关关闭；屏幕选项默认开启但禁用，打开总开关后恢复。
- [ ] 左键直切、右键和 Control＋点击菜单、Esc 收起；菜单关闭后仍能左键直切。
- [ ] 两种屏幕模式下实际睡眠／唤醒、主动锁屏、关闭显示器及重复切换。
- [ ] 实际登录项注册、取消、系统外部修改、注销再登录；本任务不主动注销或重启用户电脑。
- [ ] Apple Silicon、Intel 硬件、macOS 13 与当前稳定 macOS；编译成功不代替实机兼容性验证。
- [ ] 关于窗口在长文、深色模式、缩放和 VoiceOver 下可用，无正文裁切。

## 提交前

1. 补齐隐私／支持网站，设置构建变量，获得真实分发签名。
2. 在最终构建上执行测试与发布检查，完成上述实机和购买验收。
3. 校对商店文案、应用名称、关键词、截图、隐私标签与 reviewer notes。
4. 核对付费下载价格及地区可售，选择手动发布以便控制上线时点。
5. 开发者确认最终资料后，在 App Store Connect 提交审核；本轮不执行上传或提交。

来源：[Mac 分发准备](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution)、[AppTransaction](https://developer.apple.com/documentation/storekit/apptransaction)、[App Store Connect 定价](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/)、[审核指南](https://developer.apple.com/app-store/review/guidelines/)。

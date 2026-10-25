# 验证与验收

## 自动检查

| 命令 | 范围 |
| --- | --- |
| `bash Scripts/test.sh` | 32 项测试：断言生命周期、失败回滚和重试、偏好持久化、系统睡眠清理、登录项状态与操作 |
| `python3 Scripts/verify-localizations.py` | 源码与 String Catalog 键一致，11 语言覆盖、占位符和换行 |
| `python3 Scripts/verify-localizations.py --app <app>` | 额外核对编译资源、最低系统、菜单栏标识与隐私清单 |
| `python3 Scripts/verify-language-selection.py <app>` | 独立进程验证 11 种语言选择、版本格式和英文回退 |
| `bash Scripts/verify-live-assertions.sh` | 真实 IOKit 创建、切换和释放；隔离通知中心模拟睡眠／唤醒 |
| `python3 -m unittest discover -s Scripts/tests -v` | 商店签名和商店文案检查的回归测试 |
| `python3 Scripts/check-release-readiness.py <app>` | 正式商店导出包的签名、配置、资源及独立维护的商店文案 |

单元测试不操作真实登录项。探针不触发电脑实际睡眠。构建成功、模拟通知和 CLI 资源验证均不能替代原生 UI 与实机验证。

## 当前检查结果（2026-10-25）

- 32 项 Swift 核心测试、11 项 Python 发布检查测试通过。
- Debug、Release、AppStore 构建通过；Release／AppStore 均含 arm64 与 x86_64，临时签名校验通过。
- 44 组文案 × 11 语言的静态／编译资源检查，以及运行时语言选择与英文回退通过。
- 真实 IOKit 探针通过，结束时探针持有的断言为 0。
- 商店发布检查按预期拒绝临时签名、缺失团队、未填写版权及正式隐私／支持网址的产物。
- 原生 UI、真实登录启动、系统实际睡眠和正式商店分发未在本轮验收，见下方清单。

## 实机验收

- [ ] 左键切换、右键／Control＋点击菜单、Esc 收起，以及菜单关闭后再次左键。
- [ ] 开关图标、屏幕选项勾选与禁用状态，浅色／深色菜单栏。
- [ ] 实际等待空闲超时：两种屏幕模式、屏保／自动锁屏与系统策略的交互。
- [ ] 系统实际睡眠后会话结束，唤醒不恢复；锁屏与显示器睡眠不误关。
- [ ] 登录项注册、待允许、取消及系统外部修改，重新登录后的实际启动。
- [ ] 帮助窗口滚动、长文本、11 语言、VoiceOver，以及未配置链接时的布局。
- [ ] macOS 13、Intel 与 Apple Silicon 的实际运行。
- [ ] 正式商店分发签名、TestFlight 安装／更新及实际截图。

应用不阻止手动睡眠／锁屏，不承诺合盖运行或绕过系统安全策略。其他进程也可能持有防休眠断言；验证时按应用 PID 判断，不能仅以整机未熄屏作为证据。

# 商店图片模板与验收

## 内容顺序

采用“大标题＋简短说明＋放大的应用操作画面”，每张突出一个收益：

1. **一键开启，保持电脑唤醒**：核心用途与菜单栏开关。简体中文第二版配色已确认，场景包含下载、渲染和 Agent 任务。
2. **屏幕休息，系统保持唤醒**：总开关勾选、屏幕常亮不勾选；左侧卡片说明两种状态。简体中文样稿已确认。
3. **手动休眠，自动结束防休眠**：明确由用户主动触发休眠；本次防休眠结束，唤醒后保持关闭。展示关闭状态的空心咖啡杯、未勾选总开关与置灰的屏幕选项，配三步流程。简体中文样稿已确认。
4. **小巧常驻，简单就够了**：紧凑菜单、更多留白，说明两项核心控制，以及无需账户、本机运行。简体中文样稿已确认。
5. **源码公开，透明可查**：菜单搭配真实核心代码节选、MIT 许可与公开仓库地址。简体中文样稿已确认；公开源码与 MIT 许可证已核对。

用户提供的仓库是 <https://github.com/dowithless/keep-awake>。2026-10-25 用户推送后重新通过 GitHub 核对：仓库为 public，README、MIT LICENSE、`KeepAwake/KeepAwakeApp.swift` 和 `KeepAwake/SleepAssertionManager.swift` 均可读取。第五张的源码公开条件已满足；正式上架前仍需核对代码节选与发布版本一致。开源不代表已经通过安全审计。

五张中文视觉样稿均已确认，并通过共用模板重生成，文件 SHA-256 与已确认版本完全相同。已生成 11 种语言共 55 张，原有中英文十张保持不变，新增九种语言已检查排版。[全部语言图片与中英文对照](screenshots/README.md) · [导出及一致性记录](screenshots/verification.json)。

帮助和隐私入口不作为首发商店图片。模板的桌面、菜单为绘制示意，菜单项来自当前 String Catalog，咖啡杯使用应用相同的 SF Symbol；不应称为真实截屏。第二张的蓝框、指针和左侧状态卡片，第三张的状态流程，以及第五张的源码卡片，均为说明图层。Apple 要求截图展示应用使用中的体验，正式素材应核对发布版本，优先以真实菜单截屏替换示意层。

## 生成样稿

在仓库根目录执行：

```sh
bash Scripts/generate-store-screenshots.sh
python3 Scripts/verify-store-screenshots.py
```

- 布局模板：`Scripts/GenerateStoreScreenshot.swift`。
- 可替换文案：`docs/app-store/screenshot-copy.json`，目前包含 11 种语言各五张。
- 导出：`docs/app-store/screenshots/<locale>/` 下的 `01-keep-awake.png`、`02-display-sleep.png`、`03-manual-sleep.png`、`04-simple.png` 和 `05-open-source.png`，2560×1600、sRGB、不透明 PNG。图片与说明存入项目，编译工具和缓存仍在 `build/`。
- 文案按语言和图片编号组织。增加语言时添加对应条目；`menuLocale` 对应 String Catalog 中的语言键，`preventDisplaySleep` 决定屏幕常亮勾选状态，`isEnabled` 决定总开关及空心／实心图标。模板会检查单行宽度，溢出时应调整翻译或布局，而非压缩拉伸。

## 本地化与检查

按商店本地化语言导出，无需为每个国家重复制作。已为支持的 11 种语言提供对应文案及菜单翻译，统一顺序为核心用途、独立控制、手动休眠、简洁体验和开源透明。菜单文字读取 String Catalog；源码节选保留真实代码，不翻译其中的代码标识符或字符串。

`Scripts/verify-store-screenshots.py` 检查每种语言恰好五张、PNG 完整性、2560×1600 尺寸、不透明 RGB、sRGB、编号、菜单翻译覆盖和控制状态，并保护已确认的中文参考哈希。

- 检查标题、菜单和说明清晰可读，尤其是商店缩略尺寸。
- 展示真实已有的功能；不暗示定时、合盖运行、阻止手动睡眠等能力。
- 如采集真实素材，仅捕获目标应用窗口；复杂菜单采集可由用户手动完成。
- 不包含私人桌面内容、调试错误、待填写字段或未实现控件。
- 用户确认图片后手动上传，本地生成不执行后台上传或提交审核。

[Apple 截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) · [本地化说明](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information/) · [审核指南 2.3.3](https://developer.apple.com/app-store/review/guidelines/#accurate-metadata)

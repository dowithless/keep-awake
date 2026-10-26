# 多语言商店资料验收

更新日期：2026-10-26。以已确认的简体中文稿为基准，其余 10 种语言已补齐，共 11 种语言。所有字段保存后均已重新载入核对，未提交审核。

## 已完成内容

各语言均已核对应用名称，并完成副标题、宣传文本、描述、关键词、支持网址、营销网址和隐私政策网址。现有应用名称沿用后台已保存的名称。完整文案见 [localizations.json](localizations.json)，字段长度与 SHA-256 核对记录见 [localizations.saved.json](localizations.saved.json)。

| 商店语言代码 | 中文名称 | 应用名称 | 副标题 |
| --- | --- | --- | --- |
| en-US | 英语（美国） | Keep Awake: Prevent Sleep | Downloads, renders & AI tasks |
| zh-Hans | 简体中文 | 一键防休眠：屏幕常亮独立开关 | 下载、渲染与AI长任务，轻巧常驻菜单栏 |
| zh-Hant | 繁体中文 | 防睡眠開關：保持喚醒與螢幕常亮 | 下載、算圖與AI長任務，輕巧常駐選單列 |
| ja | 日语 | スリープ防止・画面常時オン | ダウンロード・レンダリング・AI作業に |
| ko | 韩语 | 잠자기 방지 스위치: 화면 켜짐 유지 | 다운로드·렌더링·AI 작업용 메뉴 막대 도구 |
| de-DE | 德语 | Wach halten: Display-Schalter | Für Downloads, Rendering & KI |
| fr-FR | 法语 | Anti-veille : écran allumé | Téléchargements, rendu et IA |
| es-ES | 西班牙语（西班牙） | Evita reposo: Sistema activo | Descargas, renderizado e IA |
| pt-BR | 葡萄牙语（巴西） | Tela acesa: Impedir repouso | Downloads, renderização e IA |
| ru | 俄语 | Без автосна: Долгие задачи | Загрузки, рендеринг и ИИ |
| it | 意大利语 | Niente stop: Download e agenti | Per rendering e lavori lunghi |

## 网址与共用信息

- 支持与营销网址均为公开 GitHub 仓库，首页提供支持和隐私联系方式。
- 简体中文及繁体中文使用中文隐私政策，其他语言使用英文政策；中英文政策均提供语言互链。政策正文目前只有这两种语言。
- 审核备注是全 App 共用字段，保留已确认的中文版；构建 1.0（1）仍已关联，发布方式为手动。
- 名称、副标题、宣传文本、描述分别满足 30、30、170、4000 字符限制；所有关键词不超过 100 个 UTF-8 字节。
- 价格与销售范围已保存并重新载入核对：中国大陆 ¥1 为基准，其余地区自动换算，全部 175 个国家或地区在 App 发布时供应。
- App Store 的“不收集数据”声明已由开发者发布，2026-10-26 已在后台核对；正式政策文件已在 GitHub 发布。

## 保存凭证

- [英语产品页面](../../build/app-store/evidence/localizations-en-saved.png)。
- [简体中文最终页面](../../build/app-store/evidence/localizations-zh-Hans-final.png)。
- build/ 内另有修改前备份及重新载入后的字段快照；均被 Git 忽略。

## 剩余待办

- 核对账户付费协议、收款、税务及地区合规资料的完成状态。
- 按发布清单完成人工验收，最终由开发者手动提交审核。

[中文基准与整体待办](zh-Hans-baseline.md) · [发布流程](../release/README.md)

# 付费下载与地区定价

已确认：Mac App Store 付费下载，一次购买，完整功能永久使用，无订阅、无内购。价格不是应用代码里的货币换算规则；最终由每个商店的价格计划决定。

## 规则

1. 使用该 App Store storefront 实际采用的结算货币。
2. 可选择当地结算货币的 1 单位时，设为准确的 1；包括可用的 $1.00、€1.00 等整数档位。
3. 无法设置 1 时，选择当时后台提供的最低非零档位，保持低门槛。
4. 所有销售地区采用手动价格，不能只设中国 ¥1 后直接接受 Apple 的汇率换算价。手动管理地区后由开发者维护其价格。
5. 同币种的多个 storefront 仍须逐一核对与设置。界面语言与商店定价互不绑定。

[pricing.csv](pricing.csv) 是重点市场的初始草案，新增俄语对应的俄罗斯参考价 15 RUB；俄罗斯的购买和付款可用性需额外核对。支持俄语并不代表只在俄罗斯销售。其余可售地区按照同一规则在后台补齐；当前未登录 App Store Connect，不声称已验证全量商店档位。

价格参考来自 Apple 公布的价格体系表（2022/2023 年升级资料），不是已认证的 2026 年后台最低价。最低价变化时更新 CSV；不要将草案直接当作可导入后台的 API payload。表内人民币金额是 2026-10-23 参考汇率的估算，仅用于比较用户价格，不是实际分成收入；俄罗斯暂未计算。

## 后台操作

- 账户持有人接受有效 Paid Apps Agreement，完成银行、税务和税务分类资料。
- 创建或选择 Bundle ID 对应的 macOS 应用，确认应用名称可用。
- Pricing and Availability 中选择基准地区（建议中国大陆），选择 ¥1。
- 展开额外价格档位，逐一覆写其他商店；核对每个地区的用户价格、销售可用性、生效日期及开发者 proceeds。
- 导出／记录后台最终价目表、核对日期和选择的价格点 ID，再替换本草案。
- 发布前检查 app 本身为付费，而不是误创建非消耗型内购产品；本项目没有 IAP product ID。

## 来源

- [Apple：Set a price](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/)
- [Apple 公开价格档位参考 PDF](https://www.apple.com/newsroom/pdfs/App-Store-Pricing-Update.pdf)
- [ECB：参考汇率](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html)
- [新台币参考汇率](https://www.unitdo.cc/en/currency/)

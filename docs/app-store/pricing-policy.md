# 付费下载与地区定价

已确认：Mac App Store 付费下载，一次购买，完整功能永久使用，无订阅、无内购。

## 当前规则

1. 以中国大陆为基准地区，初始价格为人民币 ¥1.00。
2. 其他 174 个国家或地区采用 Apple 自动换算价格，不设置手动地区价格。Apple 可根据税费和汇率变化调整非基准地区价格。
3. 2026-10-26 用户决定使用此自动定价方案，取代原先“各地本币 1 单位，否则最低非零档位”的草案。
4. 销售范围选择全部 175 个国家或地区，并包含 Apple 将来新增的国家或地区。实际可售仍取决于应用发布、有效协议和地区合规要求。
5. 界面语言与销售地区互相独立，不因本地化语言数量限制销售范围。

## 后台保存结果

2026-10-26 已保存并重新载入核对：基准地区为中国大陆，当前价格覆盖 175 个国家或地区，价格调整方式显示“可能进行自动调整”，供应情况显示“175 个可用”。应用仍为“准备提交”，未提交审核或发布。

[pricing.csv](pricing.csv) 记录本次保存后从后台读取的全部 175 个地区用户价格，不是未来固定价格承诺。例如：中国大陆 ¥1.00、美国 $0.99、德国 €0.99、日本 ¥150、韩国 ₩1,100。价格为用户购买价，不代表开发者实际收入。

[自动定价凭证](../../build/app-store/evidence/pricing-automatic-saved.png)与[供应范围凭证](../../build/app-store/evidence/availability-175-saved.png)位于被 Git 忽略的 build/ 中。后续调整基准价格时，应重新导出并核对价目表。

## 来源

- [Apple：Set a price](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/)
- [Apple：Manage availability](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store/)

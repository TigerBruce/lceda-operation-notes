# 03. API Validation Notes

这些结论来自实际使用嘉立创 EDA 专业版 V3.2.x 和 Run API Gateway 的现场验证。不同版本必须重新跑最小验证。

这篇文档是附录，不是新手主教程。它用于记录每个 API 的验证方法、实测行为、适用边界和禁用规则。

## 1. Validation Method

每个 API 应单独验证，不要靠猜。

推荐记录格式：

- API name。
- LCEDA Pro version。
- Run API Gateway version。
- minimal repro。
- observed result。
- safe usage rule。
- forbidden usage。
- verification artifact，例如 netlist count、source length、screenshot pixel check。

## 2. Verified Useful APIs

### Document targeting

- `DMT_EditorControl.openDocument(documentUuid)`
- `DMT_EditorControl.activateDocument(tabId)`
- `DMT_SelectControl.getCurrentDocumentInfo()`
- `DMT_Schematic.getCurrentSchematicPageInfo()`

用途：写入前确认当前页和 Board。

规则：写操作前必须用 document info / page info 确认 UUID，不靠 UI 标题猜。

### Source read/write

- `SYS_FileManager.getDocumentSource()`
- `SYS_FileManager.setDocumentSource(source)`

用途：小范围白名单修正。

风险：

- BETA API。
- 正式页禁止外部整页文件生成后直接写回。
- 写回后必须读回验证。

### Netlist export

- `SCH_ManufactureData.getNetlistFile(fileName, 'JLCEDA')`

用途：验证 schematic electrical connectivity。

注意：

- `.enet` 中 `components` 是 object，不是 array。
- 连接关系在 `components[*].pinInfoMap[*].net`。

### DRC

- `SCH_Drc.check(false,false,false)` 可作为基础布尔门禁。
- `SCH_Drc.check(true,false,true)` 在实测版本仍可能只返回 boolean，不能依赖详细错误列表。

## 3. Known Pitfalls

### Attribute bulk loops

批量 `SCH_PrimitiveAttribute.get()/modify()` 可能触发 Gateway 500。正式页避免大循环。

### Rectangle Y-axis trap

`SCH_PrimitiveRectangle.create()` 创建的 section frame 可能读回为正 Y，而主图在负 Y 区域。

处理：

- create 后立刻 `getDocumentSource()`。
- 检查 `dotY1/dotY2` 是否和附近图元同坐标系。
- 必要时只修目标 `RECT` 的 Y 字段。

### Screenshot black image

屏幕休眠或关闭显示器时，截图 API 可能返回全黑 PNG。

处理：

- 截图前保持屏幕唤醒。
- 固定视区后等待。
- 打开或像素检查 PNG。

### HTTP 500 partial success

Gateway 500 后操作可能已经部分生效。必须先读回状态再继续。

### Footprints are read-only

AI/API 可以检查并提出封装错误，但不允许直接更改器件封装。

封装修正必须由人或明确受控流程完成，并重新核对 datasheet / footprint / PCB。

## 4. Public Documentation Rule

实测记录应公开结论，不公开个人工程备份和长篇现场日志。

推荐公开：

- API name。
- version。
- minimal repro。
- observed result。
- safe usage rule。
- forbidden usage。

不推荐公开：

- 本机路径。
- 私有工程 UUID。
- 投板工程源文件。
- 大量未筛选截图。
- 未授权再分发的第三方资料。

官方公开参考设计可以作为学习材料保留；若资料许可不清楚，应改为链接索引和学习笔记。


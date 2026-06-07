# 01. Getting Started And Safe Workflow

这篇文档给第一次使用嘉立创 EDA 专业版 API / Run API Gateway 的人看。

目标：先跑通只读连接和验证流程，再允许 AI 做原理图整理。不要一上来就批量改图。

## 1. Recommended Mode

推荐使用嘉立创 EDA 专业版，不推荐从网页端开始接管。

原因：

- 专业版支持扩展 API。
- `Run API Gateway` 可以把外部脚本或 AI 工具接入 EDA。
- 本地工程更容易备份、恢复、截图、导出网表。

在线模式可以保持开启，但工程、下载包、API Gateway、截图、备份应放在非系统盘，避免 C 盘被临时文件塞满。

公开仓库不要当工程备份目录。公开仓库只放方法文档、工具和学习样板。

## 2. Install Checklist

1. 安装嘉立创 EDA 专业版。
2. 打开目标工程。
3. 在扩展管理器安装 `Run API Gateway`。
4. 确认扩展已启用。
5. 确认 EDA 窗口保持可见，电脑不要休眠或关闭屏幕。
6. 如果扩展显示未连接，先点 `Reconnect`。

端口通常在：

```text
49620-49629
```

## 3. Health Check

先找可用端口。PowerShell 示例：

```powershell
49620..49629 | ForEach-Object {
  try {
    $r = Invoke-RestMethod -Uri "http://127.0.0.1:$_/health" -TimeoutSec 2
    [pscustomobject]@{ Port = $_; Status = $r.status; EdaConnected = $r.edaConnected }
  } catch {}
}
```

期望看到：

```text
Status: ok
EdaConnected: true
```

如果 `EdaConnected` 不是 `true`：

- 确认 EDA 专业版正在运行。
- 确认工程已打开。
- 在扩展菜单里执行 `Reconnect`。
- 等 1-3 秒后再查，不要连续猛点。

## 4. First Read-Only Call

第一次调用只允许读，不允许写。

要确认：

- 当前工程。
- 当前文档。
- 当前原理图页。
- 当前选中的 board/page 是否正确。

不要根据页签标题、页签顺序或左侧树选中状态判断目标页。写操作前必须通过 UUID 或 API 返回的 document info 确认。

## 5. Targeting Gate

任何写操作前必须确认目标：

1. `DMT_EditorControl.openDocument(documentUuid)`
2. `DMT_EditorControl.activateDocument(tabId)`
3. `DMT_SelectControl.getCurrentDocumentInfo()`
4. `DMT_Schematic.getCurrentSchematicPageInfo()`

必须同时确认：

- 当前文档 UUID 是目标页。
- parent project UUID 是目标工程。
- parent schematic UUID 是目标原理图。
- title block 或页面信息显示目标 Board。

不要根据页签标题、页签顺序、左侧树选中状态判断。

## 6. Write Gate

正式页写操作必须满足：

- 已保存一份工程备份。
- 明确只操作目标 board。
- 明确只操作目标 page。
- 明确白名单对象或白名单字段。
- 不修改 footprint/package/library binding。
- 不修改非目标 Board。
- 不操作已投板或只读参考页。
- 单次请求不要混合太多动作。
- 每步等待 650-1000 ms；保存、重开、截图等待更久。

如果是团队协作，先约定权限：

```text
AI can edit: target board/page only
AI cannot edit: approved board / reference board / footprints / packages
```

## 7. First Safe Edit

第一次写操作建议只做低风险视觉对象：

- 页面标题。
- 非电气说明文字。
- 非电气边界框。
- 备注区。

不要第一次就：

- 批量删除 wire。
- 批量改 net label。
- 批量改 component attribute。
- 改 footprint/package。

## 8. Recommended Edit Loop

推荐顺序：

1. 读取源码或对象状态。
2. 生成最小改动。
3. 写回。
4. 立即读回。
5. 如果长度、对象数、关键字符串不符合预期，立刻恢复原始源码。
6. 保存。
7. 导出网表。
8. 对比关键网络计数。
9. 截图并检查截图有效性。

## 9. Netlist Verification

优先用：

```javascript
await eda.sch_ManufactureData.getNetlistFile('name', 'JLCEDA')
```

不要依赖已废弃或不稳定的旧 netlist 接口。

视觉整理类改动应保证：

- component count unchanged
- net count unchanged
- key net pin counts unchanged

如果 `.enet` SHA256 变化，先检查是否只是 BOM/Manufacturer 字段编码差异。电气判断以 `pinInfoMap` 中的 net 连接为准。

## 10. Screenshot Verification

截图前：

- 屏幕不能休眠。
- EDA 窗口应处于可渲染状态。
- 先固定视区 `zoomToRegion(...)`。
- 等待 1500-1800 ms。

截图后：

- 文件 size 非零不代表成功。
- 必须打开图片或做像素采样。
- 全黑、全白、桌面截图、旧画面都不能作为验收证据。

## 11. HTTP 500 Rule

Run API Gateway 返回 HTTP 500 后，不要立刻重试。

先读回：

- 当前页 UUID。
- 源码长度。
- 目标对象是否已创建或修改。
- 网表是否变化。

实测中，某些批量操作会“已生效但响应 500”。盲目重试会造成重复图元。

## 12. Common Beginner Mistakes

- 连续操作太快，导致 EDA 还没处理完上一步。
- 看页签名字判断目标页，结果写错 board。
- HTTP 500 后立刻重试，造成重复对象。
- 同一线段放多个同名 net label。
- net label 离芯片太近，压住引脚号或引脚名。
- 把半成品截图放进公开仓库。
- 把本机路径、UUID、工程名写进公开 README。


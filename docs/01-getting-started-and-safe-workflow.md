# 01. Getting Started And Safe Workflow

## Copy-Paste Agent Prompt

把下面整段直接复制给新的 agent：

```text
请帮我在 Windows / PowerShell 环境里安装并验证嘉立创 EDA 专业版 Run API Gateway 连接，不要只给步骤，要实际执行安装和验证。

Git 仓库：
https://github.com/TigerBruce/lceda-operation-notes.git

教程文档：
docs/01-getting-started-and-safe-workflow.md

请按这个流程做：

1. 先确认嘉立创 EDA 专业版里已经安装 `Run API Gateway` 扩展。
   具体确认方式：EDA 顶部菜单栏必须能看到 `API Gateway` 菜单。
   如果看不到 `API Gateway` 菜单，立刻暂停并告诉我：
   “请先按视频手动安装 Run API Gateway 扩展，安装完成后我再继续。”
   不要替我自动导入 `.eext`，也不要把扩展安装步骤复杂化。

2. 如果本机还没有仓库，执行：
   git clone https://github.com/TigerBruce/lceda-operation-notes.git
   然后进入仓库并读取 docs/01-getting-started-and-safe-workflow.md。
   如果本机已经有这个仓库，直接读取本地文档，不要重复克隆。

3. 使用文档里的 5 分钟 Fast Install Runbook。
   不要默认使用 npx clawhub install easyeda-api，因为实测会超时。
   Windows PowerShell 里不要直接用 npm，统一用 npm.cmd / npx.cmd。

4. 安装或确认：
   - opencode-ai
   - easyeda-api Skill
   - Run API Gateway 扩展已经由用户手动安装，并且 EDA 顶部能看到 API Gateway 菜单
   - easyeda bridge server

5. 优先使用官方直链安装 easyeda-api Skill：
   - https://image.lceda.cn/files/easyeda-api.zip
   `Run API Gateway` 扩展不要在这里自动安装；用户会按视频手动安装。

6. 不要让我手动点“重新连接”。
   确认 `API Gateway` 菜单存在后，你必须按文档用脚本自动点击 API Gateway -> 重新连接。

7. 启动 bridge server：
   $HOME\.config\opencode\skills\easyeda-api\scripts\bridge-server.mjs
   后台启动，不要阻塞终端。

8. 用 /health 检查 49620-49629：
   必须看到 service=easyeda-bridge、status=ok、edaConnected=true。
   如果 edaConnected=false，按文档自动点击 API Gateway -> 重新连接，然后再查。

9. 首次只读验证必须一个 API 一个请求，不要 Promise.all 混合多个 API：
   - return await eda.dmt_Project.getCurrentProjectInfo();
   - return await eda.dmt_SelectControl.getCurrentDocumentInfo();
   - return await eda.dmt_Schematic.getCurrentSchematicPageInfo();

10. 如果 /execute 返回 HTTP 500：
   不要立刻重试同一个请求。
   先查 /health。
   如果 EDA WebSocket 断开，先自动重连，再只重试最小只读 API。

11. 安装完成后汇报：
   - bridge 端口
   - edaConnected 状态
   - activeWindowId
   - 当前 project/document/page 的只读验证结果
   - 是否有任何步骤需要我手动确认

禁止做任何写入 EDA 工程的操作。只做安装、连接和只读验证。
```

这篇文档给第一次使用嘉立创 EDA 专业版 API / Run API Gateway 的人看。

目标：新 agent 在 5 分钟内完成本机 API 连接安装、启动、自动重连和只读验证。先跑通只读连接和验证流程，再允许 AI 做原理图整理。不要一上来就批量改图。

## 0. 5 分钟安装原则

默认不要走慢路径。

- 不要默认用 `npx clawhub install easyeda-api`。实测会卡在解析和 15 秒请求超时。
- 不要让用户去点 `重新连接`。agent 必须自己通过 EDA 顶部 `API Gateway` 菜单触发 `重新连接`。
- 不要一开始把多个 API 混在一个 `/execute` 里跑。第一次只读验证必须一个 API 一个请求。
- 不要在 HTTP 500 后盲目重试同一请求。先查 `/health`，必要时自动重连。
- PowerShell 里不要直接调用 `npm`。Windows 执行策略可能拦截 `npm.ps1`，统一用 `npm.cmd` 和 `npx.cmd`。

本教程的 5 分钟路径只覆盖：

1. 本机已安装嘉立创 EDA 专业版。
2. EDA 已打开目标工程。
3. Node.js 已安装。
4. agent 有本机 PowerShell 执行权限。

如果嘉立创 EDA 专业版本体还没安装，这一步不计入 5 分钟路径。

## 1. Recommended Mode

推荐使用嘉立创 EDA 专业版，不推荐从网页端开始接管。

原因：

- 专业版支持扩展 API。
- `Run API Gateway` 可以把外部脚本或 AI 工具接入 EDA。
- 本地工程更容易备份、恢复、截图、导出网表。

在线模式可以保持开启，但工程、下载包、API Gateway、截图、备份应放在非系统盘，避免 C 盘被临时文件塞满。

公开仓库不要当工程备份目录。公开仓库只放方法文档、工具和学习样板。

## 2. Fast Install Runbook

下面命令在 PowerShell 中执行。每一步都应该由 agent 自己执行并报告结果。

### 2.1 检查本机环境

```powershell
Get-Command node -ErrorAction SilentlyContinue | Select-Object Source,Version | Format-List
node -v
npm.cmd -v
opencode.cmd --version
```

如果 `opencode.cmd --version` 不存在，安装 OpenCode：

```powershell
npm.cmd install -g opencode-ai
opencode.cmd --version
```

实测通过版本：

```text
node v24.14.0
npm 11.9.0
opencode 1.16.2
嘉立创 EDA 专业版 V3.2.121
Run API Gateway v1.0.5
```

### 2.2 安装 easyeda-api Skill

优先用官方直链 zip，不要默认用 ClawHub。

```powershell
$SkillRoot = Join-Path $HOME '.config\opencode\skills\easyeda-api'
$SkillZip = 'C:\tmp\easyeda-api.zip'

New-Item -ItemType Directory -Force -Path 'C:\tmp' | Out-Null
New-Item -ItemType Directory -Force -Path $SkillRoot | Out-Null

Invoke-WebRequest `
  -Uri 'https://image.lceda.cn/files/easyeda-api.zip' `
  -OutFile $SkillZip

Expand-Archive -LiteralPath $SkillZip -DestinationPath $SkillRoot -Force

Push-Location $SkillRoot
npm.cmd install
Pop-Location
```

检查：

```powershell
Get-ChildItem -Force -LiteralPath "$HOME\.config\opencode\skills\easyeda-api" |
  Select-Object Mode,Length,LastWriteTime,Name |
  Format-Table -AutoSize

Get-Content -Raw -Encoding UTF8 -LiteralPath "$HOME\.config\opencode\skills\easyeda-api\package.json"
```

期望看到：

```text
SKILL.md
package.json
scripts\bridge-server.mjs
dependencies: ws
```

### 2.3 下载 Run API Gateway 扩展包

优先下载官方 `.eext` 文件到本机。不要让用户自己去网页慢慢找下载按钮。

```powershell
$GatewayEext = 'C:\tmp\run-api-gateway_v1.0.5.eext'

Invoke-WebRequest `
  -Uri 'https://image.lceda.cn/extensions/files/ec1cd4bbb33446e685b10306e0aa2e0e-run-api-gateway_v1.0.5.eext' `
  -OutFile $GatewayEext

Get-Item -LiteralPath $GatewayEext | Select-Object FullName,Length,LastWriteTime | Format-List
```

如果固定直链失效，用官方 API 自动解析最新已审核版本，不要改回人工网页下载：

```powershell
$nameInfo = Invoke-RestMethod `
  -Uri 'https://jlc-ext.com/api/v1/extensions/name?username=oshwhub&name=run-api-gateway' `
  -TimeoutSec 30

$versions = Invoke-RestMethod `
  -Uri "https://jlc-ext.com/api/v1/extensions/his_version_list?bizKey=$($nameInfo.result.biz_key)" `
  -TimeoutSec 30

$latest = $versions.result |
  Where-Object { $_.review_status -eq 4 -and $_.deleted_flag -eq 0 -and $_.file_path } |
  Select-Object -First 1

if (-not $latest) { throw 'Run API Gateway extension package was not found.' }

$GatewayEext = "C:\tmp\run-api-gateway_v$($latest.version).eext"
Invoke-WebRequest -Uri $latest.file_path -OutFile $GatewayEext
Get-Item -LiteralPath $GatewayEext | Select-Object FullName,Length,LastWriteTime | Format-List
```

可选校验包内容：

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::OpenRead('C:\tmp\run-api-gateway_v1.0.5.eext').Entries |
  Select-Object -First 30 FullName,Length |
  Format-Table -AutoSize
```

期望看到：

```text
extension.json
dist/index.js
README.md
images/logo.jpg
```

扩展元信息：

```text
name: run-api-gateway
uuid: bded3619ce6a4e60a35c7f4a84739702
displayName: Run API Gateway
version: 1.0.5
engines.eda: ~3.2.0
```

### 2.4 在 EDA 中安装扩展

如果 EDA 顶部菜单已经能看到 `API Gateway`，跳过这一节。

如果还看不到，agent 应先打开扩展包所在目录，让用户只做一次导入确认：

```powershell
Start-Process -FilePath 'explorer.exe' -ArgumentList '/select,"C:\tmp\run-api-gateway_v1.0.5.eext"'
```

在嘉立创 EDA 专业版中：

1. 打开扩展管理器。
2. 导入 `C:\tmp\run-api-gateway_v1.0.5.eext`。
3. 启用扩展。
4. 勾选扩展要求的外部交互权限。
5. 确认顶部菜单出现 `API Gateway`。

注意：导入扩展可能涉及 EDA 自身权限确认，这一步可以需要人确认；但 `重新连接` 不能要求人手动点，必须由 agent 自动触发。

### 2.5 启动 Bridge Server

先查是否已有 bridge。没有就后台启动。

```powershell
$BridgeRoot = Join-Path $HOME '.config\opencode\skills\easyeda-api'

$BridgePort = 49620..49629 | ForEach-Object {
  try {
    $r = Invoke-RestMethod -Uri "http://127.0.0.1:$_/health" -TimeoutSec 1
    if ($r.service -eq 'easyeda-bridge') { $_ }
  } catch {}
} | Select-Object -First 1

if (-not $BridgePort) {
  Start-Process `
    -FilePath 'node' `
    -ArgumentList 'scripts/bridge-server.mjs' `
    -WorkingDirectory $BridgeRoot `
    -WindowStyle Hidden

  Start-Sleep -Seconds 2
}

49620..49629 | ForEach-Object {
  try {
    $r = Invoke-RestMethod -Uri "http://127.0.0.1:$_/health" -TimeoutSec 1
    if ($r.service -eq 'easyeda-bridge') {
      [pscustomobject]@{
        Port = $_
        Service = $r.service
        Status = $r.status
        EdaConnected = $r.edaConnected
        EdaWindowCount = $r.edaWindowCount
        ActiveWindowId = $r.activeWindowId
      }
    }
  } catch {}
}
```

期望先看到：

```text
Service: easyeda-bridge
Status: ok
```

如果 `EdaConnected` 还是 `false`，执行下一节自动重连。

### 2.6 自动点击 API Gateway -> 重新连接

不要让用户点 `重新连接`。agent 应用脚本把 EDA 窗口置前并点击菜单。

这个脚本适用于 EDA 窗口最大化、顶部菜单中能看到 `API Gateway` 的情况。若坐标未命中，agent 应先截图定位菜单位置，再调整 `$menuX/$menuY/$reconnectY`，仍然由 agent 操作。

```powershell
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class LcedaMouse {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extraInfo);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
  public const uint LEFTDOWN = 0x0002;
  public const uint LEFTUP = 0x0004;
}
'@

function Click-At {
  param([int]$X, [int]$Y)
  [LcedaMouse]::SetCursorPos($X, $Y) | Out-Null
  Start-Sleep -Milliseconds 80
  [LcedaMouse]::mouse_event([LcedaMouse]::LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 80
  [LcedaMouse]::mouse_event([LcedaMouse]::LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
}

$p = Get-Process |
  Where-Object { $_.ProcessName -like 'lceda*' -and $_.MainWindowHandle -ne 0 } |
  Select-Object -First 1

if (-not $p) { throw 'LCEDA window not found. Start 嘉立创 EDA 专业版 and open the target project first.' }

[LcedaMouse]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
[LcedaMouse]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 500

[LcedaMouse+RECT]$rect = New-Object LcedaMouse+RECT
[LcedaMouse]::GetWindowRect($p.MainWindowHandle, [ref]$rect) | Out-Null

# V3.2.121 maximized window observed position:
# API Gateway top menu is near x = left + 1415, y = top + 25.
# Reconnect menu item is near x = left + 1430, y = top + 60.
$menuX = $rect.Left + 1415
$menuY = $rect.Top + 25
$reconnectX = $rect.Left + 1430
$reconnectY = $rect.Top + 60

Click-At $menuX $menuY
Start-Sleep -Milliseconds 400
Click-At $reconnectX $reconnectY
Start-Sleep -Seconds 3

Invoke-RestMethod -Uri 'http://127.0.0.1:49620/health' -TimeoutSec 5 |
  ConvertTo-Json -Depth 10
```

期望看到：

```text
edaConnected: true
edaWindowCount: 1
activeWindowId: <uuid>
```

如果仍未连接：

1. 截取 EDA 窗口。
2. 确认顶部菜单是否有 `API Gateway`。
3. 确认没有点到 `停止连接`。
4. 调整坐标后再点 `重新连接`。
5. 再查 `/health`。

## 3. Health Check

端口通常在：

```text
49620-49629
```

标准健康检查：

```powershell
49620..49629 | ForEach-Object {
  try {
    $r = Invoke-RestMethod -Uri "http://127.0.0.1:$_/health" -TimeoutSec 2
    [pscustomobject]@{
      Port = $_
      Service = $r.service
      Status = $r.status
      EdaConnected = $r.edaConnected
      EdaWindowCount = $r.edaWindowCount
      ActiveWindowId = $r.activeWindowId
    }
  } catch {}
}
```

期望看到：

```text
Service: easyeda-bridge
Status: ok
EdaConnected: true
EdaWindowCount: 1
```

列出连接的 EDA 窗口：

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:49620/eda-windows' -TimeoutSec 5 |
  ConvertTo-Json -Depth 20
```

如果有多个窗口，必须选择目标窗口，不要猜：

```powershell
$body = @{ windowId = '<target-window-id>' } | ConvertTo-Json
Invoke-RestMethod `
  -Uri 'http://127.0.0.1:49620/eda-windows/select' `
  -Method Post `
  -ContentType 'application/json; charset=utf-8' `
  -Body $body
```

## 4. First Read-Only Calls

第一次调用只允许读，不允许写。

重要：第一次只读验证必须一个 API 一个请求。不要用 `Promise.all` 混合多个 API。实测混合调用可能返回 HTTP 500 并导致 EDA WebSocket 断开。

### 4.1 读取当前工程

```powershell
$body = @{
  code = 'return await eda.dmt_Project.getCurrentProjectInfo();'
} | ConvertTo-Json

Invoke-RestMethod `
  -Uri 'http://127.0.0.1:49620/execute' `
  -Method Post `
  -ContentType 'application/json; charset=utf-8' `
  -Body $body `
  -TimeoutSec 60 |
  ConvertTo-Json -Depth 30
```

记录：

- project UUID。
- project name。
- board list。
- schematic/page list。

### 4.2 读取当前文档

```powershell
$body = @{
  code = 'return await eda.dmt_SelectControl.getCurrentDocumentInfo();'
} | ConvertTo-Json

Invoke-RestMethod `
  -Uri 'http://127.0.0.1:49620/execute' `
  -Method Post `
  -ContentType 'application/json; charset=utf-8' `
  -Body $body `
  -TimeoutSec 60 |
  ConvertTo-Json -Depth 30
```

记录：

- document UUID。
- tabId。
- parentProjectUuid。
- documentType。

### 4.3 读取当前原理图页

```powershell
$body = @{
  code = 'return await eda.dmt_Schematic.getCurrentSchematicPageInfo();'
} | ConvertTo-Json

Invoke-RestMethod `
  -Uri 'http://127.0.0.1:49620/execute' `
  -Method Post `
  -ContentType 'application/json; charset=utf-8' `
  -Body $body `
  -TimeoutSec 60 |
  ConvertTo-Json -Depth 30
```

记录：

- page UUID。
- page name。
- parentSchematicUuid。
- title block `@Board Name`。
- title block `@Page Name`。

要确认：

- 当前工程。
- 当前文档。
- 当前原理图页。
- 当前选中的 board/page 是否正确。

不要根据页签标题、页签顺序或左侧树选中状态判断目标页。写操作前必须通过 UUID 或 API 返回的 document info 确认。

## 5. HTTP 500 Recovery During Setup

安装和首次验证阶段遇到 HTTP 500，不要立刻重试同一 `/execute`。

先查 bridge：

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:49620/health' -TimeoutSec 5 |
  ConvertTo-Json -Depth 10
```

如果变成：

```text
edaConnected: false
edaWindowCount: 0
```

说明 EDA WebSocket 断开。执行第 2.6 节自动重连，然后只重试一个最小只读 API：

```powershell
$body = @{
  code = 'return await eda.dmt_Project.getCurrentProjectInfo();'
} | ConvertTo-Json

Invoke-RestMethod `
  -Uri 'http://127.0.0.1:49620/execute' `
  -Method Post `
  -ContentType 'application/json; charset=utf-8' `
  -Body $body `
  -TimeoutSec 60 |
  ConvertTo-Json -Depth 30
```

禁止在 500 后连续猛点 `重新连接` 或连续重试写操作。

## 6. Targeting Gate

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

## 7. Write Gate

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

## 8. First Safe Edit

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

## 9. Recommended Edit Loop

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

## 10. Netlist Verification

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

## 11. Screenshot Verification

截图前：

- 屏幕不能休眠。
- EDA 窗口应处于可渲染状态。
- 先固定视区 `zoomToRegion(...)`。
- 等待 1500-1800 ms。

截图后：

- 文件 size 非零不代表成功。
- 必须打开图片或做像素采样。
- 全黑、全白、桌面截图、旧画面都不能作为验收证据。

## 12. Common Beginner Mistakes

- 默认走 `npx clawhub`，结果下载和解析超时。
- PowerShell 里直接用 `npm`，被 `npm.ps1` 执行策略拦截。
- Bridge Server 没启动，就去 EDA 里反复点扩展。
- 扩展已安装，却让用户手动点 `重新连接`。
- 第一次只读调用把多个 API 混在一起，返回 HTTP 500 后断开 WebSocket。
- 连续操作太快，导致 EDA 还没处理完上一步。
- 看页签名字判断目标页，结果写错 board。
- HTTP 500 后立刻重试，造成重复对象。
- 同一线段放多个同名 net label。
- net label 离芯片太近，压住引脚号或引脚名。
- 把半成品截图放进公开仓库。
- 把本机路径、UUID、工程名写进公开 README。

## 13. 2026-06-07 Field Notes

这次现场安装的实测结论：

- 嘉立创 EDA 专业版常见 Windows 安装路径为 `C:\Program Files\lceda-pro\lceda-pro.exe`。
- EDA 版本为 `V3.2.121`。
- `opencode-ai` 可用版本为 `1.16.2`。
- `npx.cmd clawhub@latest install easyeda-api --workdir "$HOME/.config/opencode" --dir skills` 超时，不适合作为教程默认路径。
- `https://image.lceda.cn/files/easyeda-api.zip` 可以直接安装 Skill。
- `https://image.lceda.cn/extensions/files/ec1cd4bbb33446e685b10306e0aa2e0e-run-api-gateway_v1.0.5.eext` 可以直接下载扩展包。
- Bridge Server 后台进程使用 `node scripts/bridge-server.mjs` 启动。
- `/health` 成功返回 `service=easyeda-bridge`、`status=ok`。
- EDA 顶部菜单出现 `API Gateway` 后，agent 可以用鼠标坐标脚本触发 `重新连接`。
- 重连成功后 `/health` 返回 `edaConnected=true`、`edaWindowCount=1`。
- 首次只读调用应按单个 API 执行：
  - `eda.dmt_Project.getCurrentProjectInfo()`
  - `eda.dmt_SelectControl.getCurrentDocumentInfo()`
  - `eda.dmt_Schematic.getCurrentSchematicPageInfo()`
- 实测项目 UUID 为私有现场信息，不应写入公开 README。

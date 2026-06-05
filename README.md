# LCEDA 操作记忆与原理图基准

版本：2026-06-03  
用途：本目录的唯一文字基准文档。后续所有 LCEDA / 嘉立创 EDA 专业版接管、原理图整理、网表检查、PCB 前置审查，都以本文为准，并持续在本文中完善。

样板 PDF 和示例目录保留在：

- `C:\Users\OS\Desktop\LCEDA操作记忆\原理图设计样板示例`

## 当前推荐模式

- 使用嘉立创 EDA 专业版，不用网页版接管。
- 专业版可以保持“全在线”模式，前提是工程已打开、账号在线、Run API Gateway 扩展已连接。
- 本机 C 盘空间紧张，下载包、Bridge、截图、备份、工程相关文件统一放在 `D:\LCEDA-Pro`。
- 当前工程：`D:\LCEDA-Pro\projects\温度检测.eprj2`

## 本机目录

- API / Bridge 根目录：`D:\LCEDA-Pro\api-gateway`
- EasyEDA API Skill：`D:\LCEDA-Pro\api-gateway\easyeda-api-skill`
- Run API Gateway 扩展包：`D:\LCEDA-Pro\api-gateway\run-api-gateway_v1.0.5.eext`
- 扩展解包目录：`D:\LCEDA-Pro\api-gateway\run-api-gateway-eext`
- Bridge 脚本：`D:\LCEDA-Pro\api-gateway\easyeda-api-skill\scripts\bridge-server.mjs`
- Bridge 日志：`D:\LCEDA-Pro\api-gateway\bridge-server.out.log`
- 工程备份目录：`D:\LCEDA-Pro\projects\backup`

当前工程 UUID：

- 工程 UUID：`621d1c5d2976460a9b78b52445458229`
- 原理图 UUID：`1123ab9cea172a59`
- 原理图页 UUID：`fe9b4bf82ffa91e4`
- PCB UUID：`6bc7a5adfebcfdce`
- 当前原理图名称：`TEMP_ACQ_MAIN`
- 当前图页名称：`MAIN`
- 当前 PCB 名称：`TEMP_ACQ_PCB`

## 官方资料依据

- 嘉立创 EDA 专业版扩展 API Guide: https://prodocs.lceda.cn/cn/api/guide/
- 嘉立创 EDA 专业版 API Reference: https://prodocs.lceda.cn/cn/api/reference/pro-api.html
- Run API Gateway: https://ext.lceda.cn/item/oshwhub/run-api-gateway
- PCB 转原理图扩展: https://ext.lceda.cn/item/darksteel/eext-pcbtosch-tool
- 嘉立创 EDA 文件格式文档: https://prodocs.lceda.cn/cn/format/index/
- TI Schematic Design Guidelines and Review Checklist: https://www.ti.com/lit/pdf/spracu5
- TI TIDA-010956 Reference Design: https://www.ti.com/tool/TIDA-010956
- Altium schematic documentation: https://www.altium.com/documentation/altium-designer/schematic
- KiCad Eeschema documentation: https://docs.kicad.org/8.0/en/eeschema/eeschema.html

本地 API 文档：

- `D:\LCEDA-Pro\api-gateway\easyeda-api-skill\SKILL.md`
- `D:\LCEDA-Pro\api-gateway\easyeda-api-skill\guide\invoke-apis.md`
- `D:\LCEDA-Pro\api-gateway\easyeda-api-skill\references\classes\SCH_PrimitiveWire.md`
- `D:\LCEDA-Pro\api-gateway\easyeda-api-skill\references\classes\SCH_PrimitiveComponent.md`
- `D:\LCEDA-Pro\api-gateway\easyeda-api-skill\references\classes\SCH_ManufactureData.md`
- `D:\LCEDA-Pro\api-gateway\easyeda-api-skill\scripts\bridge-server.mjs`

## 安装与连接流程

1. 安装 Node.js，建议 22 LTS 或更高。
2. 在嘉立创 EDA 专业版中安装 `Run API Gateway` 扩展。
3. 扩展管理器中确认：
   - 扩展已启用。
   - 允许外部交互。
   - 可显示在顶部菜单。
4. 打开工程 `D:\LCEDA-Pro\projects\温度检测.eprj2`。
5. 启动 Bridge Server：

```powershell
Set-Location 'D:\LCEDA-Pro\api-gateway\easyeda-api-skill'
node scripts/bridge-server.mjs
```

6. Bridge 端口范围是 `49620-49629`，当前跑通端口是 `49620`。
7. 在 EDA 菜单里执行 `API Gateway / Reconnect`，或等待自动连接。
8. 健康检查：

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:49620/health' -TimeoutSec 10
```

成功状态应包含：

```text
service: easyeda-bridge
status: ok
edaConnected: true
edaWindowCount: 1
```

## 好原理图的定义

好的原理图不是“能连通”的图，而是能表达设计意图的工程文档。

好的原理图 = 把系统架构、电气连接、关键约束、设计依据、调试入口和量产信息，用清晰分层的方式表达出来，让别人能审查、布板、调试、复用。

## 六个基准要求

### 1. 系统架构清楚

原理图应先让人看懂系统由哪些模块组成，以及模块之间的关系。

必须能表达：

- 系统边界
- 电源输入和电源树
- 控制器 / 处理器
- 传感器 / 采样 / 通信 / 调试接口
- 本设计负责的范围
- 外部系统如何连接

复杂或需要交付的项目必须有 `SYSTEM_ARCHITECTURE` 或同等作用的架构页。

### 2. 电气连接可审查

不能只靠视觉判断“看起来连上了”。

必须能通过网表或连接表确认：

- 每个关键 net 连接到正确 pin
- 电源、地、复位、BOOT、时钟、通信、采样信号连接明确
- 未用引脚、NC、保留脚处理清楚
- 同名网络没有误连
- 单脚网络有明确理由，不能默认忽略

同页普通信号优先使用实体导线或导线 `net` 属性；跨页 / 层级连接才使用端口。

### 3. 关键约束明确

原理图要把会影响 PCB、调试和性能的约束写出来，而不是留给别人猜。

常见约束包括：

- 去耦电容靠近 IC 电源脚
- ADC 滤波电容靠近 ADC pin
- 模拟采样线远离噪声源
- 电源回路、功率回路、采样地、Kelvin sense
- 高 dv/dt 节点、隔离边界、差分阻抗
- 热焊盘、散热铜皮、测试点
- 固件必须遵守的时序或采样等待时间

约束应放在相关电路附近或统一备注区，不能压住器件名、引脚名、网络名。

### 4. 设计依据可追溯

关键电路不能只写“经验值”。

应能追溯到：

- Datasheet
- 官方 reference design / EVM
- 设计计算
- 选型理由
- 固件约束
- 测试或量产要求

对当前温度检测模块，设计依据至少包括：

- NTC 阻值和 B 值
- 偏置电阻值
- ADC RC 滤波时间常数
- ADC 通道切换后的等待时间
- 串口方向定义
- 3.3V MCU rail 和 ADC rail 的隔离方式

### 5. 调试入口完整

别人拿到板子后，应能根据原理图知道“先量哪里”。

必须明确：

- 关键电源轨
- GND
- Reset / Boot
- SWD / JTAG / UART
- ADC 采样点
- 通信 TX/RX
- Fault / Enable / Status
- 必要测试点或可测连接器

没有测试点也要能说明从哪个连接器或器件 pin 测量。

### 6. 量产和交接信息完整

原理图是交付物，不是临时草稿。

必须包含：

- 项目名
- 版本号
- 日期
- 图页名称
- 页码
- 设计人 / 审核人字段
- BOM 相关字段
- DNP / NP / 可选料说明
- 装配版本或变体说明
- 关键物料生命周期和封装校验记录

## 及格、好、专业的区别

及格原理图：

- 能生成 netlist
- 能导入 PCB
- 大体能工作

好原理图：

- 别人能顺着图理解系统如何工作
- 每个模块为什么这样连能看出来
- 关键网络和电源树能审查
- 重复通道排列一致
- 备注能解释关键设计依据

专业原理图：

- 可用于设计评审
- 可用于 layout 约束传递
- 可用于 bring-up
- 可用于故障定位
- 可用于 BOM 管理
- 可用于量产交接
- 后续人员能复用，不依赖口头说明

## TIDMD37A 样板学习结论

参考文件：

- `C:\Users\OS\Desktop\LCEDA操作记忆\原理图设计样板示例\tidmd37a.pdf`
- PDF 标题：`TIDA-010956 Schematic (Rev. A)`
- 厂商：Texas Instruments
- 工具：Altium Designer
- 页数：7

关键结论：

- 第 1 页是系统架构页，不是详细连线页。
- 架构页表达系统边界、能量流、信号流、本设计范围。
- 详细页按功能岛组织，不靠大框硬套。
- 大量留白是专业图纸的一部分，不是浪费空间。
- 输入在左，输出在右，电源从上进，地往下落。
- 重复通道必须几何一致，便于逐路审查。
- 注释应服务 PCB、参数选择或评审，例如 `place cap close to fets`，不是普通说明书。
- 制造/标签/版本/装配变量等信息应独立管理，不挤进电路主体。

对温度检测模块的要求：

- 必须建立 `P1 SYSTEM_ARCHITECTURE`。
- `P2 TEMP_ACQ_DETAIL` 负责网表、PCB、BOM、调试依据。
- 5 路 NTC 必须用一致几何排布。
- 网络标签必须避开器件名、引脚名、元件本体。
- 采样约束集中在备注区，不散落到电路主体中。

## 温度检测模块页结构

### P1 - SYSTEM_ARCHITECTURE

目的：让别人 30 秒内知道这块板做什么。

内容：

- RK3576 Host
- `+5V_IN`
- 3.3V LDO
- `+3V3_MCU`
- L1 / `+3V3_ADC`
- STM32F030 sampling MCU
- 5x NTC input
- UART upload
- SWD debug
- ADC sampling firmware rule

这页默认不参与网表，只表达系统架构和设计意图。

### P2 - TEMP_ACQ_DETAIL

目的：生成网表、PCB、BOM、调试依据。

推荐布局：

- 左侧：5 路 NTC 输入，纵向重复。
- 中间：STM32 MCU，ADC pins 对准 5 路输入。
- 右上：RK3576 UART / power connector。
- 中右：SWD debug。
- 下方左 / 中：MCU decoupling + ADC rail filter。
- 下方右：`+5V_IN` to 3.3V LDO + power LED。
- 右下角：采样约束和调试 checklist。

## 温度检测模块连接表

重画前必须先检查连接表，禁止直接从画线开始。

```text
NTC_CH1_ADC = R1.2, R3.2, C6.2, U1.PA0
NTC_CH2_ADC = R4.2, R5.2, C7.2, U1.PA1
NTC_CH3_ADC = R6.2, R7.2, C8.2, U1.PA2
NTC_CH4_ADC = R8.2, R9.2, C9.2, U1.PA3
NTC_CH5_ADC = R10.2, R11.2, C10.2, U1.PA4

MCU_UART_TXD = U1.PA9, FPC3.RXD_TO_RK3576
MCU_UART_RXD = U1.PA10, FPC3.TXD_FROM_RK3576

SWDIO = U1.PA13, H2.SWDIO
SWCLK = U1.PA14, H2.SWCLK

+5V_IN = FPC3.5V, LDO.VIN, LDO.CE, C2
+3V3_MCU = LDO.VOUT, U1.VDD, C3, C4, NTC pullups, SWD VREF
+3V3_ADC = L1 output, U1.VDDA, C5
GND = all local returns
```

每次 API 操作后，必须用网表 pin 列表验证，不能只看截图。

## 当前工程已知问题

已用 `SCH_ManufactureData.getNetlistFile()` 验证：

- `NTC_CH1_ADC` 到 `NTC_CH5_ADC` 只连到分压 / 滤波件，没有连到 MCU PA0 到 PA4。
- `SWDIO` / `SWCLK` 只连到 H2，没有连到 MCU PA13 / PA14。
- `MCU_UART_TXD` 只连到 FPC3，没有连到 MCU PA9。
- `MCU_UART_RXD` 当前连到 U1.PA10 和 FPC3.4，这一路是连上的。
- `+3V3_ADC` 当前没有出现在关键 pin 网表中，需要复查。

结构和表达问题：

- 没有真正的系统架构页。
- 详细页功能块之间没有稳定阅读顺序。
- 分区框过大且压到标题栏，像临时画布。
- 网络标志和文字有重叠。
- 端口标签离器件太近，压住引脚名。
- 同一页用了过多 `NetPort`，造成跨页 / 层级语义混乱。
- 电源、ADC rail、LDO 区域视觉上混在一起。

## ADC 采样设计说明

当前温度检测模块必须表达：

- NTC 使用 `10k/B3950` 分压。
- 每路 ADC 前端有 `100nF` 采样 / 滤波电容。
- `tau = (R_NTC || R_BIAS) * C_ADC`。
- 25C 附近可按 `>=2.5ms` 起步。
- 固件切换 ADC 通道后等待 `>=5*tau`。
- 丢弃切换后的第一次转换。
- 再对稳定样本做平均。
- 不要快速轮询 ADC mux，否则 ADC 采样电容和外部 RC 没有充分稳定，温度数据会飘。
- `C_ADC` 要靠近 MCU ADC pin。
- `NTC_CHx_ADC` 走线要安静，远离 UART 和 LDO 输入噪声。
- L1 用于隔离 `+3V3_MCU` 和 `+3V3_ADC`。

## API 正确用法

`/execute` 只能拿到 `eda` 对象，不能调用 `api(...)`。

代码必须以 `return await` 包裹：

```powershell
$code=@'
return await (async () => {
  const wires = await eda.sch_PrimitiveWire.getAll();
  return { wireCount: wires.length };
})()
'@

$body=@{ code=$code } | ConvertTo-Json -Depth 5
Invoke-RestMethod `
  -Uri 'http://127.0.0.1:49620/execute' `
  -Method Post `
  -ContentType 'application/json' `
  -Body $body `
  -TimeoutSec 60
Start-Sleep -Milliseconds 500
```

必须使用 PowerShell 单引号 here-string `@' ... '@`，避免 `$...` 被 PowerShell 插值破坏 JS。

错误正文捕获模板：

```powershell
try {
  Invoke-RestMethod -Uri 'http://127.0.0.1:49620/execute' `
    -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 60
} catch {
  $resp=$_.Exception.Response
  if ($resp) {
    $reader=New-Object IO.StreamReader($resp.GetResponseStream())
    $reader.ReadToEnd()
  } else {
    $_ | Out-String
  }
}
```

已验证 API：

```javascript
await eda.sch_Document.save()
await eda.pcb_Document.save('6bc7a5adfebcfdce')
await eda.dmt_EditorControl.openDocument('6bc7a5adfebcfdce')
await eda.pcb_Document.importChanges('1123ab9cea172a59')
await eda.sch_PrimitiveComponent.modify(id, { x, y })
await eda.sch_PrimitiveWire.create([x1, y1, x2, y2], 'NET_NAME')
const blob = await eda.dmt_EditorControl.getCurrentRenderedAreaImage()
```

导出当前工程快照：

```javascript
const info = await eda.dmt_Project.getCurrentProjectInfo();
const file = await eda.sys_FileManager.getProjectFileByProjectUuid(info.uuid);
```

导出的工程文件可能是 `.epro2`，不要强行保存为 `.eprj2`。

## API 已确认坑

### Bridge 30 秒超时

`bridge-server.mjs` 中：

```js
const REQUEST_TIMEOUT_MS = 30_000;
```

最小复现：

```js
return await (async () => {
  await new Promise(r => setTimeout(r, 31000));
  return { done: true };
})()
```

结果：

```json
{"success":false,"error":"Request ... timed out after 30000ms"}
```

结论：

- 大脚本执行超过 30 秒会被 HTTP `/execute` 判定为 500。
- EDA 端可能已经部分执行完成，但返回结果被 Bridge 丢弃。
- 禁止一次性执行大规模删除、创建、移动、保存、截图。
- 每个 `/execute` 控制在 10 到 15 秒内。
- 每个写操作批次后等待 500 到 800 ms。

### NetPort 不能当本页普通网络标签

官方 API：

```ts
SCH_PrimitiveComponent.createNetPort(
  direction: 'IN' | 'OUT' | 'BI',
  net: string,
  x: number,
  y: number,
  rotation?: number,
  mirror?: boolean
)
```

这是网络端口图元，不应在同一页里大量替代普通连接。

同页信号优先规则：

1. 物理导线直接连到目标引脚。
2. 必须断开表达时，用导线自身的 `net` 属性命名，但导线端点必须实际落在引脚或同网图元上。
3. 电源和地使用 `createNetFlag('Power' | 'Ground', net, x, y, ...)`。
4. 跨页或层级设计时才使用 `NetPort`。

### 只给短导线改 net 名，不等于目标引脚已连接

官方 `SCH_PrimitiveWire.create` / `modify` 支持 `net`：

```ts
create(
  line: Array<number> | Array<Array<number>>,
  net?: string,
  color?: string | null,
  lineWidth?: number | null,
  lineType?: ESCH_PrimitiveLineType | null
)
```

关键规则：

- 如果导线没有真正接触引脚，网表不会因为文字接近而合并。
- 视觉上看起来靠近不等于网表连接。
- 创建导线时如果指定 `net`，但端点落在另一个显式网络图元上，可能创建失败。
- 创建原理图导线坐标用扁平数组 `[x1,y1,x2,y2]`，不要优先用 `[[x1,y1],[x2,y2]]`。

### Netlist / DRC

`SCH_Netlist.getNetlist()` 已弃用。后续验证网表应使用：

```ts
SCH_ManufactureData.getNetlistFile(fileName?: string, netlistType?: ESYS_NetlistType)
```

`SCH_Drc.check(true, false, true)` 在当前 V3.2.121 运行时不返回详细数组，实际函数未把第三个参数传给底层，只能作为布尔 pass/fail 快速信号。详细错误需要结合底部 DRC 面板、网表导出、截图人工检查。

### 其他工具坑

- `eda.sch_Schematic.save()` 不对，保存原理图要用 `eda.sch_Document.save()`。
- `openDocument()` 偶发卡住；如果当前已经在原理图上下文，不要反复调用。
- PowerShell 截屏容易抓到 OBS 或桌面，不如用 `getCurrentRenderedAreaImage()`。
- `rg` 在本机不可用，查文件用 PowerShell `Get-ChildItem | Select-String`。
- 图框 A4 是 `sheet-symbol_a4`，属于 sheet component。
- `SCH_PrimitiveComponent.modify()` 不支持替换 `component` 字段；`setState_Component()+done()` 测试后也没有生效。
- EasyEDA 矩形框 API 创建可视 y=720 的框时传 `topLeftY=720`，读回状态会变成负值；传负值会跑到不可见区域。
- EasyEDA 矩形线宽 `0.5` 渲染几乎不可见，功能边界框建议 `lineWidth=1`、`color='#777777'`、`fillStyle='None'`。
- PCB 导入变更后可能保留内部 LED 节点 `$1N1`；不要在没确认所有 pad / track 的情况下强行改 PCB 网络名。

## 网表验证模板

```js
return await (async () => {
  const file = await eda.sch_ManufactureData.getNetlistFile('temp-acq-netlist');
  const raw = await file.text();
  const data = JSON.parse(raw);
  const nets = {};

  for (const [cid, comp] of Object.entries(data.components || {})) {
    const designator = (comp.props && comp.props.Designator) || cid;
    const pins = comp.pinInfoMap || {};
    for (const [pkey, pin] of Object.entries(pins)) {
      const net = pin.net || '';
      if (!nets[net]) nets[net] = [];
      nets[net].push(designator + '.' + (pin.number || pkey) + ':' + (pin.name || ''));
    }
  }

  return {
    NTC_CH1_ADC: nets.NTC_CH1_ADC || [],
    NTC_CH2_ADC: nets.NTC_CH2_ADC || [],
    NTC_CH3_ADC: nets.NTC_CH3_ADC || [],
    NTC_CH4_ADC: nets.NTC_CH4_ADC || [],
    NTC_CH5_ADC: nets.NTC_CH5_ADC || [],
    MCU_UART_TXD: nets.MCU_UART_TXD || [],
    MCU_UART_RXD: nets.MCU_UART_RXD || [],
    SWDIO: nets.SWDIO || [],
    SWCLK: nets.SWCLK || [],
    '+3V3_ADC': nets['+3V3_ADC'] || []
  };
})()
```

## 后续执行纪律

禁止：

- 禁止直接从“画线”开始。
- 禁止一次脚本做完整页重排。
- 禁止同页大量使用 `NetPort` 表达普通信号。
- 禁止只看截图说“连上了”。
- 禁止使用弃用的 `SCH_Netlist.getNetlist()` 作为主要验证。
- 禁止返回完整图元对象数组，容易造成返回数据过大或序列化问题。

必须：

1. 需求表
2. 系统架构
3. 功能分区
4. 连接表 / net-to-pin 表
5. 元件表 / BOM 初稿
6. 原理图绘制
7. 网表检查
8. ERC / DRC
9. 截图人工审图
10. PCB 约束备注
11. 调试和量产信息补齐
12. 更新本文档

每次写入后检查：

- 截图检查文字和网络名是否重叠。
- `getNetlistFile()` 检查关键 net 的 pin 列表。
- `sch_Drc.check(true, false, false)` 检查布尔结果。

## 当前工程下一步修复策略

先不要继续局部补丁，应按下面顺序重做详细页连接：

1. 备份当前 `.epro2`。
2. 删除本页所有 `netport`。
3. 删除错误或悬空的命名短导线。
4. 按连接表重连 NTC 五路、UART、SWD、ADC rail。
5. 导出网表，逐项检查关键 pin 列表。
6. 网表正确后再做视觉排版。
7. 最后创建或整理系统架构页。

## 常用检查命令

健康检查：

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:49620/health' -TimeoutSec 10
```

查看 Bridge 日志：

```powershell
Get-Content 'D:\LCEDA-Pro\api-gateway\bridge-server.out.log' -Tail 80
```

查看 node Bridge 进程：

```powershell
Get-CimInstance Win32_Process -Filter "name = 'node.exe'" |
  Select-Object ProcessId, CommandLine
```

## 备份和历史快照

备份目录：`D:\LCEDA-Pro\projects\backup`

关键备份：

- `温度检测.before-api-20260603-033333.eprj2`
- `温度检测.before-professionalize-20260603-035015.eprj2`
- `温度检测.before-professional-layout-20260603-042830.eprj2`
- `温度检测.before-redraw-schematic-20260603-044331.eprj2`
- `温度检测.before-sheet-a3-20260603-184824.eprj2`
- `温度检测.before-tidmd37a-clean-layout-20260603-202249.eprj2`
- `温度检测.before-netlabel-cleanup-20260603-2050.epro2`

历史截图和导出：

- `D:\LCEDA-Pro\api-gateway\schematic-error-state-before-api-redesign-doc.png`
- `D:\LCEDA-Pro\api-gateway\schematic-tidmd37a-style-pass2.png`
- `D:\LCEDA-Pro\api-gateway\schematic-netlabel-cleanup-pass2.png`
- `D:\LCEDA-Pro\projects\温度检测.exported-current-20260603-2037.epro2`
- `D:\LCEDA-Pro\projects\温度检测.exported-netlabel-cleanup-20260603-2101.epro2`

## 持续完善规则

以后每发现一次问题，都只补充到本文档，避免再分散成多个重复 Markdown。

样板 PDF、截图、工程备份可以保留独立文件；规则、流程、坑点、验收标准统一写入本文。

## 2026-06-03 实操补充：温度检测专业原理图重排

- 当前推荐页结构已经落地为 `P1_SYSTEM_ARCHITECTURE` + `P2_TEMP_ACQ_DETAIL`。P1 只放系统架构和设计意图，不画真实电气导线；P2 放真实网表、BOM、PCB 输入和设计备注。
- `SCH_PrimitiveText.create()` 最后一个 `alignMode` 参数不要传字符串 `left`，当前版本会返回 `undefined` 且不报错。稳定写法是传 `null` 或直接省略该参数。
- `SCH_PrimitiveRectangle.create()` 和文本坐标要按当前画布方向理解：A4 标题栏在低 Y 区域，主体内容应放在较高 Y 区域；分区框不要下探到标题栏。
- `SCH_PrimitiveWire.create()` 会自动合并相邻同网导线，不能用新增前后 `wireCount` 判断是否成功。必须用 `SCH_ManufactureData.getNetlistFile()` 检查目标 pin 是否进入目标 net。
- 同一页普通信号可以用命名导线，但导线端点必须实际落到 pin 或同网导线上。若路径穿过另一个 net 的端点，会被合并成短接；本次 SWDIO 曾因穿过 SWD VREF 端点而被并入 `+3V3_MCU`。
- 当前版本 `SCH_Drc.check(true,false,true)` 仍只返回布尔值。实测本工程严格模式 `false`，宽松模式 `true`；详细原因需要结合 UI DRC 面板、netlist 和 no-connect 状态人工审查。
- `SCH_PrimitiveComponent.create()` 用现有 R/C 模板新增器件时会触发 Bridge 30 秒超时且没有落件。本次未通过 API 新增 R12/R13/C11；BOOT0 已直接接 GND，NRST 标记为有意未外接，备注说明使用 STM32 内部上拉。若后续必须外置 NRST RC，应由人工先放置器件，再由 API 接线。
- 当前完成快照：`D:\LCEDA-Pro\projects\温度检测.professional-schematic-20260603-225542.epro2`。
- 当前验收截图：`D:\LCEDA-Pro\api-gateway\p1_system_architecture-pass2.png`、`D:\LCEDA-Pro\api-gateway\p2_temp_acq_detail-pass2.png`。
- 当前关键网表快照：`D:\LCEDA-Pro\api-gateway\temp-acq-final-keynets-pass2.json`。

## 2026-06-03 实操补充：P2 可读性二次重排

- P2 不能用长实线从 NTC 区跨到 MCU 区，会导致中间线束拥挤。更清楚的做法是：NTC 分压节点本地短线命名 `NTC_CHx_ADC`，MCU PA0..PA4 旁边再用同名短线引出，通过 `wire.net` 合并。
- UART、SWD 同页信号也采用短线同名网络表达，不使用跨页 `NetPort`。
- `R12/C11` 延迟落件后已用于 NRST 最小系统：`NRST = U1.4 + R12.1 + C11.2`，`R12.2 -> +3V3_MCU`，`C11.1 -> GND`。BOOT0 直接接 GND。
- H2 SWD 连接器需要和 NRST RC 拉开距离，否则网络名会压住器件和值。当前 H2 已移到右侧空白区域，只保留短线同名连接。
- 当前可读性验收截图：`D:\LCEDA-Pro\api-gateway\p2-readability-pass5.png`。
- 当前关键网表快照：`D:\LCEDA-Pro\api-gateway\temp-acq-keynets-pass5.json`。

## 2026-06-04 补充：P2 详细原理图可读性参数化规则

目标：原理图不是“线连通”，而是工程文档。P2 详细页应接近 TI tidmd37a 的阅读方式：功能块之间有足够间距，重复电路单元一致，网络标识清楚且不重叠，电气连接可由网表验证。

### 版面参数

- 页面：P2 详细页优先用 A3 或合适尺寸；只要能放下 5 路 NTC、MCU、LDO、电源滤波、UART/SWD 连接器即可，不盲目放大。
- 分组方式：优先用空白和小标题表达分区，不使用厚重红框。只有确实需要强调边界时才使用轻量线框。
- 分组间距：功能组之间至少留 25~35 mm 空白；重复 NTC 单元之间留 12~18 mm；连接器、MCU、LDO 之间不要贴边摆放。
- 同类单元：5 路 NTC 必须形状、方向、网标位置一致，形成“行扫描”阅读体验。
- 文字密度：P2 只保留必要标题和关键约束；详细设计依据放 P1/注释区，不挤压元件周围空间。

### 网络标识参数

- 同一页普通信号使用短导线 + 同名 `wire.net`，不要使用跨页 `NetPort`。
- 同一个线段同一个网络只放 1 个网络标识；重复标识没有意义，只会增加视觉噪声。
- 每个网络标识距离芯片符号边缘至少 3~5 mm，距离引脚编号和值文字至少 2~3 mm。
- 网络名较长时，例如 `NTC_CH1_ADC`、`MCU_UART_TXD`，导线短 stub 长度至少 12~18 mm，保证文字不会压到芯片边框或引脚号。
- 网络标识不要压在元件值、位号、pin name、pin number 上；若重叠，优先移动网标，其次拉长 stub，不要移动元件破坏分区。
- 电源符号和 GND 符号只在必要节点放置；同一局部电源线段不要重复堆叠多个 `+3V3_MCU` 或 `GND` 符号。

### 连线参数

- 同一功能块内部可以短线直连；跨功能块优先同名网络连接，避免长线穿过页面中央。
- 禁止让导线端点碰到其它网络端点或穿过其它网络端点；EasyEDA 会自动合并，容易造成隐性短路。
- 每根短导线只承担一个语义：传感器输出、MCU ADC 输入、电源入口、滤波后电源等，不把多个语义挤在一根线段上。
- MCU 左侧 ADC 输入应与 NTC 输出同名，但不要把 5 根长线从 NTC 区域直接拉到 MCU。
- UART、SWD、NRST 等低速信号用短 stub 对齐进入 MCU/连接器；连接器附近不要堆重复网标。

### P2 推荐布局

- 左侧：NTC SENSOR INPUTS，5 个独立重复单元，局部 `+3V3_MCU` / `GND`，输出 `NTC_CHx_ADC`。
- 中上：SAMPLING MCU / ADC，MCU 主符号，左侧 PA0~PA4 ADC 输入，UART/SWD/NRST 短 stub 分区输出。
- 右上：MCU POWER / FILTERED ADC RAIL，VDD/VSS、VDDA、磁珠或滤波电容，不与主控引脚网标重叠。
- 右下：POWER INPUT AND 3.3V REGULATOR，5V 输入、LDO、LED 指示，电源树清晰。
- 下方或侧边：RK3576 UART / POWER CONNECTOR 与 SWD DEBUG，连接器 pin order 明确：`+5V, MCU_TXD, GND, MCU_RXD`，另外两个脚接 GND/屏蔽。
- 角落：SAMPLING NOTES，只写 3~5 条关键约束：NTC 阻值、Bias、ADC 等待、首采丢弃、平均策略。

### 验收参数

- 截图放大到 100% 后，任意网络名、元件值、位号、pin number 不重叠。
- 从左到右扫读，能在 10 秒内识别：传感器输入、ADC 主控、电源、接口、调试。
- `getNetlistFile()` 中关键网络只连接预期引脚；不能出现空网络名 `""`，不能出现旧页和新页同时连入同一功能网络造成双份电路。
- 最终只保留一个参与 BOM/PCB 的 P2 详细页；其它实验页必须删除、禁用或明确隔离，否则网表会重复计入元件。
- 修改后必须截图复核，再跑关键 net pin 列表，不只看 DRC 布尔值。

## 2026-06-04 补充：网络名长度驱动出线长度

问题：MCU/IC 引脚旁的同名短导线如果长度固定，长网络名会压住 pin number、pin name 或芯片边框。不能只凭“线连上了”判断合格。

参数化规则：

- 对同一组平行进入芯片的信号线，先统计最长网络名字符数 `maxLen`。
- 估算文本宽度：`labelWidth ~= maxLen * fontSize * 0.75`，在当前 EasyEDA 默认网名字体下可先按 `maxLen * 5~6 mm-equivalent grid units` 预留。
- stub 长度必须满足：`stubLength >= labelWidth + 2 * margin`，其中 `margin` 至少 15~25 grid units。
- 对 `NTC_CHx_ADC`、`MCU_UART_TXD` 这种 11~12 字符网络名，不再使用固定 170~200 grid units 规则。P3 参考页证明更好的做法是：MCU 右移、左侧保留独立标签区、stub 保持短而统一。
- 同组信号统一用同一个 stub 起点，最长 net 名决定全组长度，不要每根线长短不一。
- 若 stub 变长后碰到左侧功能块，应优先缩短左侧功能块输出 stub 或拉大两组间距，不能让两组同名线视觉上粘成一根跨区长线。
- 验收标准：网络名右边缘距离芯片边框、pin number、pin name 至少 15~20 grid units；100% 截图下不可重叠。
## 2026-06-04 补充：P2 线长、网络名与电源网修复规则

1. 先读真实引脚坐标，不凭截图估计。
   - 用 `sch_PrimitiveComponent.getAllPinsByPrimitiveId()` 读取每个分部的真实 pin 坐标。
   - 多分部器件要先确认哪个 primitiveId 是 IO 分部、哪个是 power 分部；不要只按截图或设计ator 猜。
   - 本项目 P2 中，U1 IO 分部左侧输入真实 pin x=510；U1 power 分部 VDD/VDDA/VSS 在 x=600/700 一带。

2. 出线长度按最长网络名预留，但必须以真实 pin 端点为终点。
   - 规则：一组并行信号先取最长 net 名，预留 `labelWidth + 2*margin` 的水平空白。
   - 线段不能穿进器件 body；wire 终点必须压到 pin 坐标，不要为了让文字好看把线拉进芯片框。
   - 如果 `wire.net` 网络名压到引脚编号，公开 API 目前不能设置 `NET.positionX/Y`；不要继续靠反转 line、拆线段猜。
   - 可选处理只有三种：手动拖动网络名位置、改用可移动的 NetPort/端口符号、或重新拉开模块间距/缩短网络名。

3. EasyEDA Pro Wire API 的限制。
   - `sch_PrimitiveWire.modify()` 只支持 `line/net/color/lineWidth/lineType`。
   - `ISCH_PrimitiveWire` 只有 `setState_Line`、`setState_Net` 等公开 setter，没有网络名字坐标 setter。
   - 同一电气网络上的 wire 可能被编辑器自动合并，修改某一段 `net` 可能等价于重命名整条已连接网络。

4. 电源 flag 放置必须避开其他电源/地线。
   - Power flag/ground flag 的连接点如果压在已有网络线上，会直接把该网络改名或短接。
   - 本次错误示例：`+3V3_ADC` flag 放在 `x=700,y=300`，该位置穿过 U1 VSS/GND 竖线，导致 GND 被污染成 `+3V3_ADC`。
   - 修复原则：`+3V3_MCU -> L1.1`，`L1.2 -> +3V3_ADC -> VDDA/C5.2`，`VSS/C5.1 -> GND`，三者几何上不能交叉。

5. 每次批量修改后必须马上跑网表核对。
   - 至少核对：U1 VDD/VDDA/VSS/NRST/BOOT0、5 路 ADC、UART、SWD、FPC3 pin order、L1/C5/C11/R12。
   - 视觉截图通过不代表电气正确；以 `getNetlistFile('JLCEDA')` 的 pin net 为准。

## 2026-06-04 补充：P2 与用户 P3 参考页截图对比结论

截图文件：
- `D:\LCEDA-Pro\api-gateway\p2_current_large-compare-20260604.png`
- `D:\LCEDA-Pro\api-gateway\p3_reference_large-compare-20260604.png`
- `D:\LCEDA-Pro\api-gateway\p2_mcu_detail-compare-20260604.png`
- `D:\LCEDA-Pro\api-gateway\p3_mcu_detail-compare-20260604.png`

对比结论：

1. MCU 左侧网络标签：P3 明显优于 P2。
   - P3 的 `NTC_CHx_ADC / MCU_UART_* / SWD*` 标签在芯片左侧有足够距离，不压 pin number。
   - P2 的标签仍压到 U1 pin number，主要因为 `wire.net` 自动显示位置靠近 pin，公开 API 无法设置 `NET.positionX/Y`。
   - 后续自动排版若坚持不用 NetPort，只能通过拉大 MCU 与左侧模块间距、缩短网络名、或人工拖动网络名位置解决。

2. 模块间距：P3 更像工程图，P2 仍偏挤。
   - P3 的 NTC 单元、MCU、复位、电源之间有明确空白带。
   - P2 的 NTC 到 MCU 距离不算小，但网络名被挤在 U1 左边，视觉上仍像“线直接冲进芯片”。
   - 参数化要求：信号标签区到 IC body 至少留 20-30 grid units；模块之间至少留 80-120 grid units 的空白带。

3. 电源小系统：P2 电气已修正，但视觉仍要重排。
   - P2 网表已正确：U1 VDD->+3V3_MCU、VDDA->+3V3_ADC、VSS->GND、L1 两端正确、C5 正确。
   - P2 视觉上 U1.2、L1、C5、LDO 区域仍靠得过近，`+3V3_MCU/+3V3_ADC/GND` 文本局部拥挤。
   - 后续应把电源分成两个子块：`LDO 3V3_MCU` 和 `MCU power / ADC filter`，不要把 LDO、U1.2、L1/C5 挤成一团。

4. 连接器/复位：P3 表达更清楚。
   - P3 的 FPC、NRST RC、BOOT0 GND 结构清晰，局部线短、标签不重复。
   - P2 现在电气正确，但复位和连接器区还需要按 P3 的“短线 + 单标签 + 局部单元”方式再整理。

后续排版优先级：
1. 先保持网表正确，不再为了移动文字破坏连接。
2. 先把 P2 的 U1 左侧标签问题解决：人工拖 `wire.net` 标签，或允许 NetPort。
3. 再重排电源区，把 LDO、U1.2、L1/C5 拆成两个清晰子块。
4. 最后统一模块标题、注释、页框标题和器件编号。

## 2026-06-04 补充：本轮 P2 优化后的硬规则

本轮动作：
- P2 MCU IO 分部已按 P3 风格右移，U1.1 当前 `x=620,y=600`，左侧有效 pin x=540。
- MCU 左侧信号 stub 采用 P3 参考页的短线风格：起点 x=485，终点 x=540，长度约 55 grid units。
- RK3576 连接器 FPC3 已从右侧挪到左下独立区域，标题改为 `RK3576 UART / POWER CONNECTOR`。
- LDO/LED 电源块整体左移，避免贴右边框；LDO 输入/地线按短 stub 重建。

关键结论：

1. `wire.net` 标签不可通过公开 API 单独移动。
   - 不要继续尝试改 `NET.positionX/Y`，当前公开 `SCH_PrimitiveWire` 只支持 `line/net/color/lineWidth/lineType`。
   - 解决标签压 pin number 的主方法是：移动 IC、拉开模块、统一 stub 起点。
   - P3 风格不是长线，而是短 stub 加足够空白；长线会让页面看起来像跨区直连，反而降低可读性。

2. netflag 不能当普通 component 移动。
   - 普通器件可以 `sch_PrimitiveComponent.modify(id,{x,y})`。
   - `componentType='netflag'` 用 `modify()` 容易 500 或失败。
   - 正确流程：记录旧 netflag 的 net/type/坐标 -> `createNetFlag(type, net, newX, newY, rotation, mirror)` -> 删除旧 netflag。

3. 导线穿过引脚坐标就会电气连接。
   - 本轮错误示例：为了让 LDO VIN 和 CE 都接 `+5V_IN`，一条竖线从 `(755,355)` 到 `(755,335)` 穿过 VSS pin `(755,345)`，直接把 `+5V_IN` 和 `GND` 短接。
   - 修复方式：不要用一条线穿过中间 pin；改成两个同名短 stub：
     - C2.2/VIN：`[680,355,755,355]`，net `+5V_IN`
     - CE：`[735,335,755,335]`，net `+5V_IN`
   - 对 GND 也用局部短 stub，不用复杂多分支折线。

4. 复杂 polyline 会被 EasyEDA 自动重排/合并。
   - `create([A,B,C,D,E,F], net)` 或 `modify(line=多点)` 可能被编辑器重排成不可读甚至危险的线型。
   - 分支网络优先拆成多根简单线；必要时删除旧 wire 后重新创建。
   - 修改后如果 DRC 失败，先检查几何短路，再删除重建局部 wire，不要只重复写同一个 net 名。

5. 网表校验格式要按 JLCEDA 实际结构读取。
   - `getNetlistFile()` 返回的 `components` 是内部 uniqueId 对象，不是数组。
   - 正确读取方式：`Object.values(netlist.components || {})`，再用 `c.props.Designator` 找 `U1/FPC3/LDO1`。
   - `getNetlistFile()` 可能在 DRC 失败时返回 `undefined`；先跑 `sch_Drc.check(false,false,false)`。

6. 电源修改后的必查项。
   - LDO1：VIN/CE -> `+5V_IN`，VSS -> `GND`，VOUT -> `+3V3_MCU`。
   - C2：输入电容上端 -> `+5V_IN`，下端 -> `GND`。
   - FPC3：pin1 `+5V_IN`，pin2 `MCU_UART_TXD`，pin3 `GND`，pin4 `MCU_UART_RXD`，pin5/6 `GND`。
   - U1：VDD pin1/17 -> `+3V3_MCU`，VDDA pin5 -> `+3V3_ADC`，VSS pin16/32 -> `GND`，BOOT0 pin31 -> `GND`。

7. 截图复核经验。
   - 全页截图容易因为 `zoomToRegion()` 坐标不准而偏移；关键模块应分别截 MCU、连接器、LDO、电源分部。
   - 高倍率局部截图中文字会显得很大，不能据此判断实际图纸比例；用同一倍率对比 P2/P3 才有意义。
   - 最终验收必须同时满足：截图无重叠、软 DRC 为 true、关键 netlist pin map 正确。

## 2026-06-04 补充：EasyEDA 缩放/截图 API 正确用法

本轮确认：之前截图总是很小、偏到空白区，是 `zoomToRegion()` 参数理解错误。

正确规则：

1. 优先使用 `zoomTo(x, y, scaleRatio, tabId)`。
   - `x,y` 是视口中心坐标。
   - `scaleRatio=180` 表示 180%。
   - 实测 MCU 区域可用：`zoomTo(620, 600, 180, tabId)`，截图清晰且不会跑到空白。

2. `zoomToRegion()` 的参数不是 `left, top, width, height`。
   - 官方签名应按区域边界理解：`zoomToRegion(left, right, top, bottom, tabId)`。
   - 之前错误示例：`zoomToRegion(20, 300, 1130, 520, tabId)` 被误当成 `x,y,w,h`，实际会把 top 设成 1130，导致画面偏到空白。
   - 若继续用 region，必须先用对象坐标计算边界，而不是随手填宽高。

3. 推荐截图倍率。
   - MCU/连接器细节：`zoomTo(centerX, centerY, 180~220)`。
   - 整体结构对比：`zoomTo(centerX, centerY, 90~130)`。
   - 不要用过高倍率评判文字大小；高倍率只用于检查重叠和引脚连接。

4. 每次截图前固定流程。
   - `activateDocument(tabId)`。
   - 等 800 ms。
   - `zoomTo(centerX, centerY, scaleRatio, tabId)`。
   - 等 1000 ms。
   - `getCurrentRenderedAreaImage(tabId)`。

## 2026-06-04 决策：以 P2_TEMP_ACQ_DETAIL_1 为基准页

用户已明确：`P2_TEMP_ACQ_DETAIL_1` 已画完并作为当前基准，后续以这个页面为准。

执行规则：

1. 不再把旧 `P2_TEMP_ACQ_DETAIL` 作为专业版式目标。
   - 旧页只能作为 API 操作实验和反例复盘。
   - 后续不要继续在旧页上追求“优化到 TI 风格”，避免浪费时间。

2. `P2_TEMP_ACQ_DETAIL_1` 是 golden reference。
   - 版式、分区、重复 NTC 单元、MCU 短 stub、连接器表达方式，都以该页为准。
   - 若需要继续自动化操作，先截图并读取该页对象坐标，形成参数表后再操作。
   - 未经确认不要改动该页，尤其不要批量移动或删除对象。

3. 后续若需要整理其它页。
   - 先复制/参照 `P2_TEMP_ACQ_DETAIL_1` 的结构。
   - 只做低风险改动：文字统一、页标题、注释、网表检查。
   - 每次改动后必须检查：软 DRC、FPC3 pin order、U1 电源/ADC/UART/SWD、LDO 输入输出。

4. 当前缩放基准继续沿用。
   - 细节截图优先 `zoomTo(x, y, 180~220, tabId)`。
   - 整体截图优先 `zoomTo(x, y, 90~130, tabId)`。
   - 不再使用错误的 `zoomToRegion(left, top, width, height)` 写法。

## 2026-06-04 补充：截图归档规则

用户要求：之后的工作截图按时间保存在 `C:\Users\OS\Desktop\LCEDA操作记忆` 下，便于人工审查。

执行规则：

1. 截图统一保存到：
   - `C:\Users\OS\Desktop\LCEDA操作记忆\截图\YYYYMMDD_HHMMSS\`

2. 文件命名：
   - `YYYYMMDD_HHMMSS_页面名_区域名_z倍率.png`
   - 同目录保存 `YYYYMMDD_HHMMSS_manifest.json`
   - 同目录保存 `YYYYMMDD_HHMMSS_审图笔记.md`

3. 本轮基准截图：
   - `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260604_212939\`
   - 页面：`P2_TEMP_ACQ_DETAIL_1`
   - 截图：overview、mcu_reset_swd、ntc_inputs、power_connector

4. 后续每次优化流程：
   - 修改前截图。
   - 小步修改。
   - 软 DRC 和关键网表检查。
   - 修改后截图。
   - 更新同目录审图笔记。

5. 当前基准页学习结论：
   - 以空白和重复单元表达结构，不靠红框或长线。
   - NTC 输出与 MCU 输入用同名短 stub 分离，中间留足空白。
   - MCU、复位、电源、LDO、接口分区清楚，局部只保留必要网络标签。
   - 网络名不压 pin number，不在同一线段重复放多个相同连接符号。

## 2026-06-04 补充：P2_TEMP_ACQ_DETAIL_1 持续审查发现

本轮复核文件：

- 截图目录：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260604_231644\`
- 电气复核：`C:\Users\OS\Desktop\LCEDA操作记忆\电气复核\20260604_231522\`

发现 1：`+A3V3_MCU` 和 U2 VDDA 的关系需要复核。

- 当前 `+A3V3_MCU` 连接 L2.2、C16.2、5 路 NTC 上拉电阻。
- 当前 U2 pin5 `VDDA` 连接 `+3V3_MCU`，不是 `+A3V3_MCU`。
- 对 NTC 比例采样，传感器激励和 ADC 参考/VDDA 不同源时，滤波磁珠压降或噪声可能进入测量误差。
- 推荐审查：若追求采样精度，优先让 NTC 激励和 VDDA 共用滤波后的模拟电源域，或在原理图注释中说明不同源理由。

发现 2：旧页仍参与项目级网表。

- 当前项目 netlist 中同时能看到旧页器件 `U1/FPC3/LDO1` 和基准页器件 `U2/FPC1/LDO2`。
- 多页原理图默认可能都参与 BOM/PCB，后续出制造数据前必须确认只保留一个有效详细页。
- 推荐审查：删除旧页、禁用旧页 BOM/PCB 参与，或明确标注旧页为参考页。

执行规则：

- 发现电气风险时先记录和截图，不直接修改用户已投出的基准页。
- 真正改 `P2_TEMP_ACQ_DETAIL_1` 前，必须先确认：是否允许改已投出版，以及是否同步更新 PCB。

## 2026-06-04 补充：P2_TEMP_ACQ_DETAIL_1 参数化基准

目的：把用户认可的 `P2_TEMP_ACQ_DETAIL_1` 固化为可复用版式参数。以后整理其它页或重画第二页时，先按这些参数排版，再看截图微调，不再凭感觉连续拖动。

### 基准页身份

- 页面名：`P2_TEMP_ACQ_DETAIL_1`
- TabId：`a29be14345affdfa@621d1c5d2976460a9b78b52445458229`
- 角色：golden reference，不经确认不要批量修改。

### 功能区坐标

- `NTC SENSOR INPUTS`：左侧重复阵列，核心元件 x 约为 105 / 205 / 265。
- `SAMPLING MCU / ADC`：MCU 主符号 `U2.1` 在 x=620, y=655。
- `MCU POWER / FILTERED ADC RAIL`：`U2.2` 在 x=1020, y=595；滤波元件在 x=890~975, y=590~720。
- `RK3576 UART / POWER CONNECTOR`：`FPC1` 在 x=145, y=265。
- `SWD DEBUG`：`H1` 在 x=230, y=95。
- `3.3V REGULATOR`：`LDO2` 在 x=710, y=390。

### NTC 重复单元参数

5 路 NTC 行坐标：

- CH1：R14 x=105 y=790，C17 x=205 y=770，R15 x=265 y=770。
- CH2：R16 x=105 y=705，C18 x=205 y=685，R17 x=265 y=685。
- CH3：R18 x=105 y=615，C19 x=205 y=595，R19 x=265 y=595。
- CH4：R20 x=105 y=525，C20 x=205 y=505，R21 x=265 y=505。
- CH5：R22 x=105 y=435，C21 x=205 y=415，R23 x=265 y=415。

参数化规则：

- 行距：85~90 坐标单位；不要压缩到小于 80。
- 每路三件套水平分布：NTC 上拉电阻、滤波电容、下拉/基准电阻之间保持约 60~100 坐标单位。
- 输出 net 水平端点到 x=320 左右即可，不要拉长线跨到 MCU。
- NTC 区和 MCU 区之间用同名短 stub 关联，中间保留空白，表达“功能块链接”而不是“长线硬连”。

### MCU 左侧短 stub 参数

基准页 MCU 左侧信号 stub：

- `NTC_CH1_ADC`：x=485->540, y=735。
- `NTC_CH2_ADC`：x=485->540, y=725。
- `NTC_CH3_ADC`：x=485->540, y=715。
- `NTC_CH4_ADC`：x=485->540, y=705。
- `NTC_CH5_ADC`：x=485->540, y=695。
- `MCU_UART_TXD`：x=485->540, y=635。
- `MCU_UART_RXD`：x=485->540, y=625。
- `SWDIO`：x=485->540, y=595。

参数化规则：

- 进入芯片前的 stub 长度约 55 坐标单位；长网络名仍要保证文字不压 pin number。
- 网络文字左边界到芯片边缘至少留 30~40 坐标单位。
- 同一根 stub 只保留一个同名网络标识；重复标识必须视为噪声。

### 接口短线参数

- FPC1 pin1 `+5V_IN`：x=250->165, y=285。
- FPC1 pin2 `MCU_UART_TXD`：x=250->165, y=275。
- FPC1 pin3 `GND`：x=250->165, y=265。
- FPC1 pin4 `MCU_UART_RXD`：x=250->165, y=255。
- H1 `SWDIO`：x=165->210, y=100。
- H1 `GND`：x=165->210, y=90。

参数化规则：

- 连接器区域用短线 + 单标签，不要把 UART/SWD 长线直接拉回 MCU。
- 用户确认的 RK3576 连接器实际 pin 序必须保持：`+5V, MCU_TXD, GND, MCU_RXD`，另外两个脚接 GND/屏蔽。
- 不加测试点。

### 当前自动审查项

每轮截图同时检查：

- 软 DRC 是否为 true。
- 项目级 netlist 是否仍同时包含旧页 `U1/FPC3/LDO1` 和基准页 `U2/FPC1/LDO2`。
- `FPC1`、`H1`、`LDO2`、`U2` 的关键 pin net 是否符合设计意图。
- 是否存在同内容同坐标重复文本。当前基准页发现 CH1~CH5 文本对象各重复 5 份，应标为维护风险；未经确认不要直接删除。
- U2 pin5 `VDDA` 必须接 `+A3V3_MCU`，与 5 路 NTC 上拉共用滤波模拟 3.3V 域。

### 2026-06-04 23:50 最新 audit 结论

最新有效复核目录：

- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_000100\`

确认正确：

- `FPC1` pin order：1 `+5V_IN`，2 `MCU_UART_TXD`，3 `GND`，4 `MCU_UART_RXD`，5 `GND`，6 `GND`。
- `H1`：1 `+3V3_MCU`，2 `SWDIO`，3 `GND`，4 `SWCLK`。
- `LDO2`：VIN/CE `+5V_IN`，VSS `GND`，VOUT `+3V3_MCU`。
- `U2`：PA0~PA4 连接 `NTC_CH1_ADC`~`NTC_CH5_ADC`，PA9/PA10 连接 UART，PA13/PA14 连接 SWD，BOOT0 接 GND。
- 脚本已加入 expected-pin 自动判定，最新结果 `validation.pass = true`，失败项 0。
- 脚本已加入旧页/基准页 pin-net 差异比较，最新发现 1 个差异：`U1 -> U2` pin5 `VDDA`，旧页为 `+3V3_ADC`，基准页为 `+3V3_MCU`。

必须决策：

- 项目级 netlist 同时包含旧页 `U1/FPC3/H2/LDO1` 和基准页 `U2/FPC1/H1/LDO2`。出 PCB/BOM 前必须只保留一个有效详细页。
- 旧页 `U1` 的 VDDA 是 `+3V3_ADC`，基准页 `U2` 的 VDDA 是 `+3V3_MCU`；这不是单纯命名差异，而是模拟电源域决策差异。
- 基准页 CH1~CH5 的文字对象各重复 5 份，属于维护风险。若确认基准页可继续修改，优先删除重复文字，只保留每路 1 个 `CHx`。

### 2026-06-04 23:58 STM32F030 ADC 精度依据

官方资料：

- STM32F030x4/x6/x8/xC datasheet: https://www.st.com/resource/en/datasheet/stm32f030k6.pdf
- ST AN2834, How to optimize the ADC accuracy in STM32 MCUs: https://www.st.com/resource/en/application_note/an2834-how-to-optimize-the-adc-accuracy-in-the-stm32-mcus-stmicroelectronics.pdf

对本项目有约束的结论：

- STM32F030 的 ADC 转换输入范围是 `0..VDDA`，所以 NTC 分压输出、ADC 参考/模拟供电、滤波电源域必须一起审查。
- datasheet 的典型 ADC 条件基于 `VDD = VDDA = 3.3 V`，且电源对 `VDD/VSS`、`VDDA/VSSA` 都要求靠近引脚放置滤波/去耦电容。
- ADC 表格给出 `RAIN` 外部输入阻抗、`RADC` 采样开关电阻、`CADC` 采样保持电容；在 `fADC=14 MHz` 时，采样时间越短，允许的外部阻抗越低。
- datasheet 明确建议每次上电后做 ADC calibration。
- AN2834 说明 STM32 ADC 是 switched-capacitor/SAR 结构；高源阻抗信号会因为采样电容充电/放电不充分产生附加误差。
- AN2834 对超高阻抗源的方案是硬件加外部电容时，固件必须配合单次转换和转换间隔 `tC`；不能连续快速转换，否则外部电容会被周期性充电并积累误差。

本项目推荐表达：

- 若追求 NTC 采样精度，优先把 NTC 上拉源和 MCU `VDDA` 放在同一个滤波后的模拟 3.3V 域，或在原理图注释中明确“为什么 NTC 激励和 VDDA 不同源”。
- 固件说明应写入图纸备注或设计文档：切换 ADC 通道后等待 RC/采样电容稳定，丢弃首个转换，再平均稳定样本；不要连续快速轮询 5 路 ADC。
- 当前基准页已修正为 `U2 VDDA = +A3V3_MCU`，与 NTC 上拉同源，符合采样精度优先的方案 A。

### 2026-06-05 00:46 VDDA 修正记录

本轮对 `P2_TEMP_ACQ_DETAIL_1` 做了最小电气修正：

- 删除 U2.2 pin5 处旧 `+3V3_MCU` netflag。
- 在同一连接点创建 `+A3V3_MCU` power netflag。
- netlist 已确认：U2 pin5 `VDDA` -> `+A3V3_MCU`。
- 软 DRC 保持 true。
- 自动审查脚本的 U2 pin5 期望值已同步改为 `+A3V3_MCU`。

后续版式微调：

- C14/C15 数字电源去耦左移，为 U2.2 左侧释放 VDDA 标识空间。
- U2.2 pin5 `VDDA` 改为同页 NET stub：wire net = `+A3V3_MCU`，不再把 power netflag 压在芯片 pin 上。
- C14/C15 下端曾因 GND netflag 重建后未被线网吸收而短暂变成内部网 `$3N716`；修正方式是把 C14/C15 下端公共 wire 的 net 显式设为 `GND`。
- 自动审查脚本已把 `L2/C14/C15/C16` 纳入 expected-pin，避免只检查 U2 而漏掉去耦和滤波网络。

执行原则：

- NTC 上拉源、ADC `VDDA`、滤波后模拟 rail 必须作为一个精度域审查。
- 不要把 `VDDA` 单独接回未滤波 `+3V3_MCU`，除非在原理图备注中明确写出不同源的设计理由和误差评估。
- 这种改动会影响 PCB 网络，继续 PCB 前必须重新导入/同步网表，而不是沿用旧 PCB 连接。
- EasyEDA 中 netflag 看起来接在线上，不代表 netlist 一定吸收；改电源/地标识后必须检查相关器件 pin net，不能只看 DRC。

## PCB 前置决策清单

当前不建议直接继续导入 PCB，原因不是基准页连错，而是项目级交付状态还没收敛。

### 必须先确认

1. 最终参与 PCB/BOM 的详细页是哪一页。
   - 推荐：保留 `P2_TEMP_ACQ_DETAIL_1` 为唯一有效详细页。
   - 风险：旧页 `P2_TEMP_ACQ_DETAIL` 仍在 netlist 中，可能导致 BOM/PCB 双份元件。

2. ADC 模拟电源域怎么定。
   - 当前决策：方案 A，`VDDA` 与 NTC 上拉共用滤波后模拟 3.3V，即 `+A3V3_MCU`。
   - 原因：当前目标是采样精度，传感器激励和 ADC 参考/模拟供电同源更容易控制比例误差。

3. 是否允许继续修改已投出的基准页。
   - 若允许：先清理 CH1~CH5 重复文本对象，再处理 VDDA/模拟电源域。
   - 若不允许：基准页保持不动，只在下一版工程中修正。

### 可自动执行但需要确认后再做

- 删除或禁用旧详细页，防止 `U1/FPC3/H2/LDO1` 继续参与制造输出。
- 删除重复 CH 文本对象，每路只保留一个 `CHx`。
- `U2 VDDA` 已改到滤波模拟 rail；后续重点是同步 PCB 网络并复查去耦、电源标识。

### 不建议自动执行

- 不自动删除旧页：这会影响 BOM/PCB 和已有布局关联。
- 不再把 `VDDA` 改动当作待确认项；当前已按采样精度优先方案执行。
- 不自动同步 PCB：当前原理图仍有项目级重复页风险，直接导入可能扩大错误。

### 自动截图与审查脚本

脚本：

```powershell
C:\Users\OS\Desktop\LCEDA操作记忆\tools\Invoke-LcedaBaselineCapture.ps1
```

默认只读，不修改工程。输出到：

```powershell
C:\Users\OS\Desktop\LCEDA操作记忆\截图\YYYYMMDD_HHMMSS\
```

运行方式：

```powershell
powershell -ExecutionPolicy Bypass -File 'C:\Users\OS\Desktop\LCEDA操作记忆\tools\Invoke-LcedaBaselineCapture.ps1'
```

截图 API 规则：

- 每步至少等待 500 ms。
- 先 `activateDocument(tabId)`，等待 800 ms。
- 用 `zoomTo(centerX, centerY, scaleRatio, tabId)`，等待 1000 ms。
- 再 `getCurrentRenderedAreaImage(tabId)`。
- 不使用错误的 `zoomToRegion(left, top, width, height)` 写法。

### 2026-06-04 23:48 截图脚本修正

本机验证结果：

- PowerShell 5 读取无 BOM 的 `.ps1` 时，会把脚本里的中文路径按 ANSI 解析。
  - 错误表现：输出到 `LCEDA鎿嶄綔璁板繂\鎴浘` 之类乱码目录。
  - 修正：脚本内部不要直接写中文路径和中文窗口标题；用 Unicode code point 组装 `LCEDA操作记忆`、`截图`、`审图笔记`，窗口用进程名 `lceda-pro` 匹配。

- EasyEDA Pro V3.2.121 当前环境下，DMT 视图控制 API 不可靠驱动可见 UI。
  - `activateDocument()`、`activateSplitScreen()`、`zoomTo()`、`zoomToAllPrimitives()` 都能返回成功或区域值。
  - 但系统截图和 `getCurrentRenderedAreaImage()` 看到的可见画布没有随之变化。
  - `generateIndicatorMarkers(..., zoom=true)` 也没有驱动当前可见视图。
  - 因此不能把 API 返回的 `area` 当成截图已经切换视口的证据。

- 当前可靠截图策略：
  - 默认抓取 EasyEDA 当前窗口系统截图，文件名：`YYYYMMDD_HHMMSS_P2_TEMP_ACQ_DETAIL_1_current_window.png`。
  - 同时保存 `audit.json`、`manifest.json`、`审图笔记.md`。
  - 只有显式需要复测 API 缓存行为时，才使用脚本参数 `-UseApiRenderedAreaShots`。

最新有效截图目录：

- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_000100\`

### 2026-06-05 01:46 P2_TEMP_ACQ_DETAIL_1 整理记录

本轮以 `P2_TEMP_ACQ_DETAIL_1` 为唯一详细页基准继续整理，先处理会影响工程判断的硬问题，再处理视觉可读性。

已执行：

- 删除旧详细页 `P2_TEMP_ACQ_DETAIL`，UUID `fe9b4bf82ffa91e4`。
- 删除前已备份工程：
  - `D:\LCEDA-Pro\projects\backup\温度检测_before_schematic_page_cleanup_20260605_013305.eprj2`
- 删除后项目级 netlist 不再同时包含旧页 `U1/FPC3/H2/LDO1` 和基准页 `U2/FPC1/H1/LDO2`。
- `SCH_ManufactureData.getNetlistFile()` 复核通过，当前有效器件数 29。
- `FPC1/H1/LDO2/U2/L2/C14/C15/C16` 关键 pin-net 校验通过。
- 清理 `CH1` 到 `CH5` 同坐标重复文本对象：每路原来叠 5 个，只保留 1 个。
- `duplicateTexts` 从 5 组降为 0。
- 补入工程文档层标题和采样说明：
  - `NTC SENSOR INPUTS`
  - `SAMPLING MCU / ADC`
  - `MCU POWER / ADC RAIL`
  - `POWER INPUT AND 3.3V REGULATOR`
  - `RK3576 UART / POWER CONNECTOR`
  - `SWD DEBUG`
  - `SAMPLING NOTES`
- 采样备注已写入图页：通道切换后等待 `>=5*tau`、丢弃首次转换、再平均稳定样本，禁止快速轮询 ADC mux。

最新有效截图目录：

- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_014651\`

### 2026-06-05 01:46 EasyEDA API 新坑

- `SCH_PrimitiveText.create(x, y, ...)` 创建文本后，`get()` 读回是正常页面坐标。
- `SCH_PrimitiveText.modify(id, { y })` 的返回对象可能显示负 Y，例如返回 `-815`，但随后 `get(id)` 读回仍是正常正坐标 `815`。
- 因此文本修改后不能只信 `modify()` 返回值，必须再 `get()` 复核，并抓当前窗口截图确认。
- `DMT_Schematic.deleteSchematicPage(pageUuid)` 可用于删除旧图页；删除前必须先做 D 盘工程备份。
- `zoomToAllPrimitives(tabId)` 在本轮能把视图恢复到模块总览，但历史上不稳定；截图仍以当前窗口系统截图为准。

### 2026-06-05 01:46 版式参数补充

- 模块标题字号：
  - 大模块标题用 8 到 10，不再用 11 以上，避免压到 A4 图框和第一行网络名。
  - 标题颜色沿用深蓝紫 `#2B168F`，加粗。
- 标题间距：
  - 标题到最近网络名/电源符号至少留 10 到 15 坐标单位。
  - 标题不要贴 A4 顶框；如果顶框附近已有电源符号，优先缩小标题字号，而不是把标题压到线或符号上。
- 连接器标题：
  - `RK3576 UART / POWER CONNECTOR` 当前位置约 `x=35, y=350, fontSize=8`。
  - 标题必须避开 FPC 上方 GND 符号，不能压在地符号或连接器引脚名上。
- NTC 标题：
  - `NTC SENSOR INPUTS` 当前约 `x=35, y=815, fontSize=8`。
  - 第一行 `+A3V3_MCU` 和 `CH1` 已经很靠近标题，后续若继续优化，优先整体下移 NTC 五路阵列，而不是继续把标题挤到顶框。
- MCU/网络标签：
  - MCU 左侧 stub 仍按 `x=485 -> 540` 的短线表达。
  - 对最长网络名 `MCU_UART_TXD` / `MCU_UART_RXD`，要保证文字右边界不碰 pin number；如果重排，stub 长度按最长标签估算，不按最短 `SWDIO` 估算。
  - 同一条 stub 或同一线段只保留一个网络名，重复 net 标识视为噪声。
- 说明区：
  - `SAMPLING NOTES` 当前约 `x=500, y=315`，说明文本从 `y=280` 向下排列。
  - 说明用于记录设计约束，不用于解释 UI 或画图方法。

### 2026-06-05 01:58 MCU Stub 与重复标识修正

本轮继续根据局部截图修正可读性：

- MCU 左侧信号 stub 从 `x=485 -> 540` 改为 `x=415 -> 540`。
- 覆盖网络：
  - `NTC_CH1_ADC` 到 `NTC_CH5_ADC`
  - `MCU_UART_TXD`
  - `MCU_UART_RXD`
  - `SWDIO`
  - `SWCLK`
- 目的：按最长网络名估算线长，让网络名与 MCU pin number 之间留出明确空隙。
- 修改后局部截图显示网络名不再贴住 pin number。
- 删除 FPC1 pin1 同一线段上的多余 `+5V_IN` power flag，只保留 wire net 文本表达。
- 删除后 netlist 复核：
  - FPC1.1 仍为 `+5V_IN`
  - FPC1.2 仍为 `MCU_UART_TXD`
  - FPC1.3 仍为 `GND`
  - FPC1.4 仍为 `MCU_UART_RXD`
  - FPC1.5/FPC1.6 仍为 `GND`
  - U2 PA0~PA4/UART/SWD/VDDA 均保持正确。

执行规则补充：

- 同一线段不要同时放 power flag 和 wire net 标签，除非确实需要强调电源入口。
- 删除 netflag 前必须确认该 wire 自身已有正确 `net` 属性。
- 删除后必须用 `SCH_ManufactureData.getNetlistFile()` 验证连接，而不是只看截图。
- MCU 左侧信号 stub 的默认长度应按最长标签计算；当前建议 `125` 坐标单位左右。

最新有效截图目录：

- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_015758\`

### 2026-06-05 02:03 P1 架构页同步

`P1_SYSTEM_ARCHITECTURE` 是文字/框图架构页，不参与真实元件网表；`P2_TEMP_ACQ_DETAIL_1` 是真实 netlist、BOM、PCB 来源。

本轮修正 P1 中的旧命名：

- `FPC3 6-PIN BOUNDARY` -> `FPC1 6-PIN RK3576 BOUNDARY`
- `L1 ferrite bead` -> `L2 ferrite bead`
- `+3V3_MCU -> +3V3_ADC` -> `+3V3_MCU -> +A3V3_MCU`
- `VDDA isolated from digital rail` -> `VDDA and NTC bias on filtered rail`
- `R_BIAS=10k to +3V3_MCU` -> `R_BIAS=10k to +A3V3_MCU`
- `H2: VREF / SWDIO / GND / SWCLK` -> `H1: VREF / SWDIO / GND / SWCLK`
- `NRST not routed; internal pull-up` -> `NRST RC pull-up / reset filter`
- `P2_TEMP_ACQ_DETAIL contains...` -> `P2_TEMP_ACQ_DETAIL_1 contains...`

截图结论：

- P1 系统窗口截图可能仍显示 P2 画布，属于 EasyEDA 可见 UI/Bridge 刷新错位。
- 本轮 `-UseApiRenderedAreaShots` 能正确渲染 P1 架构页。
- P1 当前有效 API 渲染截图目录：
  - `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_020259\`

### 2026-06-05 02:17 VDDA 标签避让与地线恢复

问题：

- U2.2 pin5 `VDDA` 的 `+A3V3_MCU` 标签压住芯片边框和 `VDDA` 引脚文字。
- 直接反向修改 wire 端点无效，EasyEDA 会把线段端点标准化回芯片侧，标签仍靠近 U2.2。

最终处理：

- 删除压字的 VDDA wire net 文本表达。
- 新增 `+A3V3_MCU` power flag，位置约 `x=760, y=540`。
- VDDA stub 改为 dogleg：从 power flag 区域走到 U2.2 pin5，wire 自身不带 net 文本。
- U2 pin5 网表复核仍为 `+A3V3_MCU`。

连带坑：

- 调整 VDDA power flag 后，C14/C15 下端曾再次掉成内部网 `$3N716`。
- 只对旧地线 `modify(..., net:'GND')` 不稳定，读回 net 会被清空。
- 有效恢复方式：删除旧地线，重新 `SCH_PrimitiveWire.create([825,570,860,570], 'GND')`，再确认 C14/C15 pin1 为 `GND`。
- 随后可尝试把新地线 wire net 清空，让 GND 符号接管；本轮验证 C14/C15 pin1 仍保持 `GND`，且减少地线文本噪声。

当前全量审计：

- 目录：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_021731\`
- Soft DRC: true
- Duplicate text groups: 0
- Old page and golden page both in netlist: false
- Expected pin validation pass: true

### 2026-06-05 02:22 副本工程树标识

工程树仍存在 `Board2 / TEMP_ACQ_PCB_1`，当前 API 未暴露可靠的 Board/PCB 删除接口。

已执行的低风险整理：

- 将副本 schematic `c8802f269da230fa` 重命名为 `ARCHIVE_DO_NOT_USE_TEMP_ACQ_MAIN_1`。
- 副本页 `11f803da4d6cfc82` 的 `modifySchematicPageName()` 返回 true，但 `getSchematicPageInfo()` 读回仍是 `P2_TEMP_ACQ_DETAIL_1`，说明该 API 对此副本页名未真正生效或需要 UI 刷新。
- 主 schematic `TEMP_ACQ_MAIN` 未改名，主页面仍为：
  - `P1_SYSTEM_ARCHITECTURE`
  - `P2_TEMP_ACQ_DETAIL_1`

最终快速审计：

- 目录：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_022241\`
- Soft DRC: true
- Duplicate text groups: 0
- Old page and golden page both in netlist: false
- Expected pin validation pass: true

### 2026-06-05 02:26 Title Block 同步

已同步交付信息：

- `P1_SYSTEM_ARCHITECTURE` 更新日期从 `2026-06-03` 改为 `2026-06-05`。
- `P2_TEMP_ACQ_DETAIL_1` 已确认：
  - Update Date: `2026-06-05`
  - Page Name: `P2_TEMP_ACQ_DETAIL_1`
  - Page No / Count: `2 / 2`

API 经验：

- `modifySchematicPageTitleBlock(true, titleBlockData)` 是对当前激活页生效，不带 page UUID。
- 修改 title block 前必须先 `activateDocument(tabId)` 并等待约 1000 ms。
- `@Update Time` 可能由 EasyEDA 自动写当前时间，不完全按传入值保持。

最终快速审计目录：

- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_022658\`
- Soft DRC: true
- Duplicate text groups: 0
- Old page and golden page both in netlist: false
- Expected pin validation pass: true

### 2026-06-05 01:46 剩余工程树问题

当前主设计 `Board1 / TEMP_ACQ_MAIN / P2_TEMP_ACQ_DETAIL_1` 的网表已干净。

工程树中仍有副本：

- `Board2`
- `TEMP_ACQ_MAIN_1`
- `TEMP_ACQ_PCB_1`

该副本当前未在主网表审计中造成重复 designator，但会让工程树显得不专业。后续如需清理，应单独做“副本 Board/PCB 清理”步骤；当前已确认的 API 只有 `DMT_Schematic.deleteSchematic()`，没有直接暴露 PCB/Board 删除接口，不能盲删。

### 2026-06-05 12:20 器件值和网络名可读性规则

本轮问题：原理图虽然连通，但部分器件只显示 `={Value}` 或 `={Manufacturer Part}`，导致审图时看不到真实值；局部说明文字如果放错位置，也会变成新的视觉噪声。

必须执行的检查：

- 扫描所有 `part`：`name` 不能为空，不能保留 `={Value}` / `={Manufacturer Part}` 这类模板字符串。
- 同步写入 `otherProperty.Value`，不要只改可见 `name`，否则 BOM/属性和图面表达不一致。
- 扫描制造网表：有效网络不允许出现 `$3N...` 这类自动匿名网。空网只允许用于明确 NC 或未用引脚。
- 原理图上的关键电源/信号必须能直接读到名称：`+5V_IN`、`+3V3_MCU`、`+A3V3_MCU`、`GND`、`NRST`、`NTC_CHx_ADC`、`MCU_UART_TXD/RXD`、`SWDIO/SWCLK`。
- `power flag` 必须挂在支线端点或真实连接点。不要放在线段中点后假设 EasyEDA 会自动吸附；中点未吸附会造成网表变成 `$3N...`。
- 不要为了说明 NC/unused 随手加大段文字到电气区域。若已有 X 标记和采样说明，优先保持干净；说明文字只放在 notes 区或模块外空白处。

本轮已写入的显示值：

- `C12/C13 = 1uF`
- `C14/C15/C16/C17/C18/C19/C20/C21/C22 = 100nF`
- `R13/R15/R17/R19/R21/R23/R24 = 10k`
- `R14/R16/R18/R20/R22 = 10k NTC B3950`
- `L2 = BLM15AG221SN1D`
- `LDO2 = ME6211C33`
- `LED2 = White 0603`
- `FPC1 = 1.25-4PWB`
- `H1 = PM127V-04P`
- `U2 = STM32F030K6T6`

本轮有效截图目录：

- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_122605\`

### 2026-06-05 13:10 P1/P2 可读性迭代规则

本轮继续按“工程文档”标准整理，而不是只追求连通。

P2 细节页规则补充：

- U2.2 `VDDA` 局部不要用很长的横向 NET 线穿过 C14/C15 去耦区；这种线虽然能连通，但视觉上会把电容和值切开。
- 若 `+A3V3_MCU` 电源符号压住 U2.2 的料号或 `VDDA` 引脚文字，优先使用短竖向 stub，并把电源符号旋转到文字朝外的位置。
- 同一功能小块内只保留必要的网络名。C14/C15 的 `GND` 地符号是实际连接点，不能因为看起来像浮动文字就删除；删除前必须用 netlist 验证。
- notes 区文字不能贴到 title block 边线上。低价值说明例如额外 `NC:` 行，如果 X 标识和 NC 引脚已经表达清楚，应删除而不是挤在标题栏上方。
- 修改后必须同时检查截图和 `sch_ManufactureData.getNetlistFile('check.json')`：`U2.5 VDDA = +A3V3_MCU`、C14/C15 下端为 `GND`、匿名 `$3N...` 网络为 0。

P1 架构页规则补充：

- P1 只做非电气系统框图；不要用 schematic wire 表达架构箭头，避免污染网表。
- 架构页应保留 6 到 8 个主框：RK3576 Host、FPC1 Interface、LDO2 Regulator、ADC Analog Rail、5x NTC Inputs、STM32 Sampling MCU、Debug/Reset、Firmware Sampling Constraint。
- 模块框线在全页视图中太淡时，把 `lineWidth` 提到 2；框内文字仍用 7 左右，避免为了放大而互相压字。
- 箭头只用短 `->` 放在模块间距中；网络名、器件型号、约束信息放在模块框内。不要把 `-> +5V_IN / UART` 这种长箭头文字挤进正文行。
- 页标题必须在图框内，不要压到 A/B/C/D 坐标区或跑到图框外。
- 架构页可以缩写长网络组名，例如 `NTC_CH1_ADC .. NTC_CH5_ADC` 在框图中写成 `NTC_CH1..5_ADC`；完整网络名留在 P2 细节页。
- 全页截图下模块标题不够醒目时，标题字号可提到 10，但正文先保持 7，避免再次出现文字重叠。

本轮有效截图目录：

- P2 细节页：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_131000\`
- P1 架构页：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_130011\`
### 2026-06-05 15:12 优秀原理图基准：网络学习后的硬规则

参考资料：
- TI `SPRACU5E` Schematic Design Guidelines and Schematic Review Checklist：原理图应在设计阶段就按 guideline 执行，并在 layout 前用 checklist 自检，目标是减少功能/性能问题、bring-up 时间和返板风险。来源：https://www.ti.com/lit/ug/spracu5e/spracu5e.pdf
- Altium 可读性文章：所有 nets 都应命名，未命名自动网名不能表达信号用途；designator/value/net label 都要留足空间。来源：https://resources.altium.com/p/creating-elegant-and-readable-schematics
- Altium connectivity 文档：同页 Net Label 是逻辑连接；跨页应使用 Port/Sheet Entry/Power Port 等有明确作用域的对象，不能混用后靠猜。来源：https://www.altium.com/documentation/altium-designer/schematic/creating-circuit-connectivity
- KiCad Eeschema 文档：一个 net 只能有一个最终名称；多个不同标签会触发 ERC 或只选一个名称进入网表；图形文字/形状可用于文档说明，不应影响电气。来源：https://docs.kicad.org/7.0/en/eeschema/eeschema.html
- Cadence checklist：按输入在左、输出在右组织；保持网格；避免 text/note/reference/wire/symbol 重叠；每个器件显示 reference 和 value；删除无意义连接/标注。来源：https://resources.pcb.cadence.com/blog/2024-electrical-schematic-design-checklist

本项目以后按这些参数执行：

- 页结构：P1 只做系统架构页，不进真实 netlist；P2 是唯一有效详细原理图页，参与 BOM/PCB/netlist。
- P1 架构页：外部系统在左，模块边界用红框，接口柱放边界处；上方走电源树，下方走模拟采样链，右侧放 MCU/debug；不要用电气 wire 表达框图连接，只用 rectangle/text。
- P2 详细页：同一页内用短 wire + 本地 NET label；不要用跨页符号；同一线段只放一个网络标识。
- 信号流：输入在左、处理在中、输出/调试在右；电源从左/上进入，分配到各功能块；模拟采样链尽量横向保持同一节奏。
- 文字间距：网络名右边界到芯片 pin number 至少留 12 坐标单位；模块标题到底下第一个对象至少留 15 坐标单位；说明文字不要贴图框或标题栏。
- 长网络名：按最长标签估算 stub，`NTC_CHx_ADC` / `MCU_UART_TXD` / `MCU_UART_RXD` 这类标签默认留 120 坐标单位以上的出线长度，禁止压到芯片边框或 pin number。
- 器件值：所有器件必须显示真实 value，不能出现 `={Value}`、`={Manufacturer Part}` 或空 value；电容、电阻、磁珠、连接器、MCU/LDO 都必须能在图面直接读出用途。
- 审图验收：截图只是视觉证据；必须同时跑 `SCH_ManufactureData.getNetlistFile()`，检查 Soft DRC、重复文本、匿名 `$3N...`、关键 pin-net。
- EasyEDA API：`SCH_PrimitiveText.create(..., alignMode)` 必须用合法值，实测 `0` 可创建且读回归一为 `6`；不要用 `20`，否则可能静默不创建文本。
- EasyEDA API：Text/Rectangle create 有时返回 `undefined`，不能依赖返回 primitiveId；创建后用 `getAll()` 复核数量和内容。
- EasyEDA API：连续生成后 UI 可能缓存旧对象；正确流程是清空对象 -> 保存 -> F5 刷新 -> 系统窗口截图复核。若 F5 后出现多代叠加，说明之前未彻底清空，必须先删净再重建。
- P1 图框：官方 titleBlock API 当前在本工程对 P1 可能返回 `Cannot convert undefined or null to object`；可用非电气 rectangle/text 手动画边框和明细表，但必须避开架构图和 firmware notes。

### 2026-06-05 15:35 P1/P2 本轮整理结果

P1 处理结论：

- 已清空 P1 上多代叠加的架构对象；清空时实际删除 `241` 个文本和 `30` 个矩形，说明之前画面混乱的主要原因是旧对象未清干净。
- 重新生成单一 P1 架构页：外部 RK3576 Host、FPC1 边界、TEMP_ACQ_MODULE 红框、电源树、5 路 NTC 前端、STM32F030K6T6 MCU、Debug/Reset、Firmware Sampling Constraint。
- P1 手动画图框/明细表；不再调用失败的官方 titleBlock API。
- 删除 P1 上容易误读为电气连接点的过滤电源竖向穿线，改成短文字箭头说明 `+A3V3_MCU`。
- P1 当前对象审计：`texts=87`、`rectangles=39`、重复文本 `0`、小于 5 号字文本 `0`。

P1 当前审图截图：

- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_150106\P1_api_render_rev2_no_vertical_line.png`
- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_150106\P1_with_manual_titleblock_z80.png`
- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_150106\P1_api_render_rev3_revision_history.png`
- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_150106\P1_revision_history_detail.png`

P2 处理结论：

- P2 继续作为唯一真实 netlist/BOM/PCB 详细页。
- `Invoke-LcedaBaselineCapture.ps1 -SkipImages` 审计通过：Soft DRC true，重复文本 0，旧页和基准页没有同时进入 netlist，关键 pin-net 全通过。
- `Invoke-LcedaBaselineCapture.ps1 -UseApiRenderedAreaShots` 已保存局部截图，MCU I/O、VDDA/电源滤波、连接器/SWD 区可读性基本通过。
- 需要注意：P2 中 GND netflag 可能在局部截图看起来像悬空 `+GND`，删除前必须先确认它不是 BOOT0/C14/C15/U2 VSS 的真实 GND 命名来源。

P2 当前审图截图：

- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_230601\20260605_230601_P2_TEMP_ACQ_DETAIL_1_mcu_io_z190.png`
- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_230601\20260605_230601_P2_TEMP_ACQ_DETAIL_1_vdda_filter_detail_z230.png`
- `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_230601\20260605_230601_P2_TEMP_ACQ_DETAIL_1_connector_swd_z200.png`

P2 机器审图补充：

- `part` 数量：30。
- `badNames=0`：没有空显示名、没有 `={Value}` / `={Manufacturer Part}` 模板值。
- `badWireCount=0`：没有 `$3N...` 匿名网。
- `emptyPinCount=0`：没有空 pin-net 连接风险。

继续优化方向：

- P1 如果继续追 TI 样式，优先改视觉层级：增大关键模块标题、减少正文句子、把线束标签放在线束外侧，不再增加更多说明文字。
- P2 如果继续追 TI 样式，优先做局部微调：GND netflag 的视觉位置、LDO 输入 `+5V_IN` 标签重复感、Notes 与 title block 的安全间距。
- 所有修改后必须走：保存 -> F5 -> 截图 -> `getAll()` 对象审计 -> `getNetlistFile()` 电气审计。

最终复核：

- P1：`texts=94`、`rectangles=44`、重复对象 `0`、Revision History 局部可见。
- P2：最终审计目录 `C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_231941`。
- P2：Soft DRC true、重复文本 0、旧页/基准页未同时进入 netlist、关键 pin-net 全通过。

### 2026-06-05 23:45 P1 v6 架构页继续优化记录

本轮目标不是再堆说明，而是把 P1 做成能表达设计意图的系统架构图；P2 继续作为唯一真实电气页。

已执行：

- 先备份工程：`D:\LCEDA-Pro\projects\backup\温度检测_before_p1_arch_v4_20260605_232805.eprj2`。
- P1 v4：清空旧 P1 文本/矩形后重建大块框图；删除旧对象 `94` 个文本、`44` 个矩形。
- P1 v5：修正固件约束框越过红色模块边界的问题，删除压到 MCU 标题附近的外部 `VDDA + NTC bias` 注释和红色方向符号。
- P1 v6：删除长 UART 线上重复的 `MCU_UART_TXD / MCU_UART_RXD` 文本。该信息已经在 FPC1 pin、MCU body 和 P2 细节页表达，重复网络名会变成视觉噪声。
- P2 只审图不改网表：重新截图并跑审计，Soft DRC true，重复文本 0，旧页/基准页未同时进入 netlist，关键 pin-net 全通过。

P1 v6 当前机器审图：

- `texts=86`
- `rectangles=32`
- `wires=0`
- `components=0`
- `duplicateTextGroups=0`
- `tinyTexts=0`

本轮截图：

- P1 v4：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_233028\20260605_233028_P1_SYSTEM_ARCHITECTURE_v4_api_z105.png`
- P1 v5：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_233829\20260605_233829_P1_SYSTEM_ARCHITECTURE_v5_api_z105.png`
- P1 v6：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_234006\20260605_234006_P1_SYSTEM_ARCHITECTURE_v6_api_z105.png`
- P2 本轮截图/审计：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_234038\`
- P2 最终快速审计：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_234452\`

新增参数化规则：

- P1 主结构至少占图框有效宽度的 70%，不要缩在页面中间；标题栏和 revision history 只占底部文档区。
- P1 只允许 `Text` 和 `Rectangle` 表达架构，禁止 wire/component/netflag，避免污染真实网表。
- P1 模块边界必须包住模块内说明；任何说明框不得穿出红色系统边界。
- P1 网络/接口名只在必要位置出现一次。若同一信息已经在模块 pin 列表和目标模块 body 中表达，不要再写在长线上。
- P1 长连接线上优先保留箭头和颜色，不写长网络名；完整网络名留在 P2。
- P2 中看到类似 `+GND` 的对象时，先查 `SCH_PrimitiveComponent.get()`。本轮确认这些对象是库里的 `ground-gnd` netflag，不是普通漂浮文字；删除前必须先确认 C14/C15、BOOT0、U2 VSS 等 pin-net 仍为 `GND`。
- P2 的地符号可读性问题优先通过移动/替换等效 `ground-gnd` 解决，不允许直接删除后靠猜。

### 2026-06-05 23:50 P2 电源输入区微调

问题：

- `LDO2` 的 `VIN` 和 `CE` 都靠近同一处显示 `+5V_IN`，虽然网表正确，但视觉上像重复标签。
- 更专业的表达应为：`CE` 通过短线实际并到 `VIN` 的 `+5V_IN` 节点，图面只保留一个主要 `+5V_IN` 标识。

已执行：

- 修改 `CE` 输入线：从 `LDO2.3` 绕开 `VSS` 线后接到 `VIN` 的 `+5V_IN` 线上。
- 保存、F5 刷新并重新截图。
- 审计目录：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_234929\`

复核结果：

- Soft DRC: true
- Duplicate text groups: 0
- Old page and golden page both in netlist: false
- Expected pin validation pass: true
- `LDO2.1 VIN = +5V_IN`
- `LDO2.2 VSS = GND`
- `LDO2.3 CE = +5V_IN`
- `LDO2.5 VOUT = +3V3_MCU`

新增规则：

- 当同一器件相邻引脚需要接同一电源网时，优先用清楚的短线把引脚实际连到同一节点，只保留一个网络标识。
- 若中间隔着 `VSS/GND` 引脚，不允许直接竖线短接；必须绕开地线，修改后立刻跑 pin-net 审计。

### 2026-06-05 23:55 P1 Host 子块优化

问题：

- P1 v6 的 `RK3576 HOST` 框太空，虽然不重叠，但不像工程文档里的功能结构表达。

已执行：

- P1 v7：在 Host 框内增加 3 个子功能块：
  - `+5V SOURCE`
  - `UART PORT`
  - `GND / SHIELD`
- P1 v7 截图发现旧 Host 正文仍在，和新子块重叠。
- P1 v8：删除旧 Host 正文 `+5V source to module`、`UART TX/RX interface`、`GND return + shield`，只保留子功能块。

P1 v8 当前审图：

- `texts=89`
- `rectangles=35`
- `wires=0`
- `components=0`
- `duplicateTextGroups=0`
- `tinyTexts=0`

截图：

- P1 v7：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_235323\20260605_235323_P1_SYSTEM_ARCHITECTURE_v7_api_z105.png`
- P1 v8：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260605_235534\20260605_235534_P1_SYSTEM_ARCHITECTURE_v8_api_z105.png`

新增规则：

- 在已有大框内增加子块前，必须先删除或移动原来的正文行；否则会形成“新结构 + 旧说明”叠加。
- 空白不是问题，但功能边界空到没有信息时，应补子块而不是补长段落。

### 2026-06-06 00:18 P1 v9-v12 按 TI 样板继续重构

参考样板：

- `C:\Users\OS\Desktop\LCEDA操作记忆\原理图设计样板示例\tidmd37a.pdf`
- 已导出样板截图：`C:\Users\OS\Desktop\LCEDA操作记忆\参考样板截图\tidmd37a\`

从 `tidmd37a.pdf` 第 1 页抽出的结构特征：

- 左侧是外部控制器大竖框。
- 中间是窄竖条接口连接器。
- 右侧是目标系统边界，内部按功能块组织。
- Revision History 放右上角，不和主图混在一起。
- 系统边界只包功能系统，不包标题栏。

已执行：

- P1 v9：重建为 `RK3576 HOST` + `FPC1 INTERFACE CONNECTOR` + `TEMP_ACQ_MODULE` 的 TI 风格结构。
- P1 v10：放大 NTC 五行空间，扩展 debug 区，但红色边界下沿压进标题栏，判定失败。
- P1 v11：尝试用 `SCH_PrimitiveRectangle.modify()` 缩小红色边界，结果边界消失；确认此 API 在当前环境有 Y 坐标方向坑。
- P1 v12：删除旧边界并重新 `create()` 边界；边界恢复，并只包功能区，不再压标题栏。

当前 P1 v12 审图：

- `texts=95`
- `rectangles=41`
- `wires=0`
- `components=0`
- `duplicateTextGroups=0`
- `tinyTexts=0`

截图：

- 样板截图：`C:\Users\OS\Desktop\LCEDA操作记忆\参考样板截图\tidmd37a\tidmd37a-1.png`
- P1 v9：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260606_000341\20260606_000341_P1_SYSTEM_ARCHITECTURE_v9_api_z105.png`
- P1 v10：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260606_000652\20260606_000652_P1_SYSTEM_ARCHITECTURE_v10_api_z105.png`
- P1 v11：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260606_001059\20260606_001059_P1_SYSTEM_ARCHITECTURE_v11_api_z105.png`
- P1 v12：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260606_001349\20260606_001349_P1_SYSTEM_ARCHITECTURE_v12_api_z105.png`
- P1 v12 全页低倍率：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260606_001525\20260606_001525_P1_SYSTEM_ARCHITECTURE_v12_full_z75.png`

P2 本轮最终快速审计：

- 审计目录：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260606_001717\`
- Soft DRC: true
- Duplicate text groups: 0
- Old page and golden page both in netlist: false
- Expected pin validation pass: true
- Legacy/golden pin-net differences: 0

新增规则：

- P1 系统边界可以用虚线红框，但只包功能系统，不包 title block、revision history、页脚说明。
- `SCH_PrimitiveRectangle.modify()` 在本环境可能把 Y 坐标方向写坏；修改大边界优先 delete + create，不要原地 modify。
- Bridge 同时执行两个会 `activateDocument()` 的审计脚本会互相抢当前页；P1/P2 审计不要并行跑。
- 低倍率截图容易显得主图偏小；审图应同时保留全页低倍率图和工作倍率图，不能只看一种缩放。

### 2026-06-06 01:09 P1 v15-v20 架构页迭代记录

本轮继续对齐 `tidmd37a.pdf` 第 1 页的系统框图表达：左侧外部控制器、中央接口柱、右侧红色目标系统边界、上方电源链、下方采样链、右侧 MCU/debug。

已执行：

- P1 继续保持非电气架构页：`wires=0`、`components=0`，只用 `Text` 和 `Rectangle` 表达系统关系，避免污染 P2 真实网表。
- v15 重新生成 TI 风格骨架后，发现 Run API Gateway 单次 `/execute` 有约 30 秒硬超时。超时后的 JS 仍可能继续慢慢落件，导致后续重复文本/矩形叠加。
- v16 删除长标签 `UART: MCU_TXD / MCU_RXD`、`NTC_CH1..5_ADC`、`SWD/NRST`，改为短标签 `UART LINK`、`ADC BUS`，避免线段上重复表达已经在模块内说明的信息。
- v17 将 UART 关系线从电源块底边下移到电源链和 NTC 块之间的空白走廊，避免长线贴住功能块边框。
- v18 将 `FPC1 INTERFACE` 从接口柱 pin 列中移到接口柱左侧空白带，使 pin 定义和接口名称分离。
- v19 删除接口左侧短箭头旁的重复 `+5V / UART / GND / SHIELD` 标签，只保留彩色箭头；这些信息已由 Host 子块和 FPC pin 列表达。
- v20 发现 `ADC SAMPLING CONSTRAINT` 灰框压住 NTC 下半部分并越过红色系统边界，将其移到左下文档说明区，和功能架构分离。

当前 P1 机器审计：

- `texts=86`
- `rectangles=37`
- `wires=0`
- `components=0`
- `duplicateTextGroups=0`
- `duplicateRectGroups=0`
- `tinyTexts=0`

当前截图：

- P1 v20 全页 API 渲染：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260606_010653\20260606_010653_P1_SYSTEM_ARCHITECTURE_v20_api_full_z60.png`
- P1 v20 窗口截图：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260606_010653\`
- P2 最终审计：`C:\Users\OS\Desktop\LCEDA操作记忆\截图\20260606_010904\`

新增参数化规则：

- 架构图中，同一信息最多出现一次。若 Host 子块和 FPC pin 列已经说明 `+5V/UART/GND`，短箭头旁不再重复写网络名。
- 长关系线必须走在功能块之间的空白走廊，至少离相邻功能块边框 15 坐标单位；不能贴着块边或穿过块内说明文字。
- 接口柱标题和 pin 列分开：竖排标题放在接口柱侧边空白带，pin 编号/信号名保留在柱内。
- Firmware/ADC 约束属于设计说明，不应压住功能块，也不应跨越系统边界。优先放在独立 notes 区，和真实功能链路保持视觉分离。
- Run API Gateway 单次执行超过 30 秒可能返回超时，但未必停止执行。发生超时后必须等待 5 秒，再跑文本/矩形坐标去重；不要立刻再次全量生成。
- 截图前若 EasyEDA 窗口最小化，`CopyFromScreen` 会得到 `-32000,-32000` 的小黑图。必须先 `ShowWindow(..., 9)` 还原窗口再截图。
- `getCurrentRenderedAreaImage()` 返回的是 `Blob`，不是 base64 字符串；必须 `await blob.arrayBuffer()` 后写入字节。
- API 渲染截图的局部缩放可能缓存或哈希相同；局部验收优先用窗口截图，全页结构可用 API 渲染图。

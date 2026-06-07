# 02. Schematic Quality And Reference Study

好的原理图不是“能连通”的图，而是能表达设计意图的工程文档。

好的原理图 = 把系统架构、电气连接、关键约束、设计依据、调试入口和量产信息，用清晰分层的方式表达出来，让别人能审查、布板、调试、复用。

## 1. Why Reference Designs Matter

大厂参考设计不是垃圾附件，而是原理图质量基准。

这个仓库保留 `原理图设计样板示例/` 和 `参考样板截图/`，目的不是备份 PDF，而是把优秀工程文档的表达方式沉淀成可执行规则。

## 2. Study Priority

优先学习：

- `tidmd37a.pdf`：系统分层、功能分区、页间组织、接口表达都清楚，适合作为主要审美基准。
- `TIDA-010979_E1_Sch.PDF`：功能块边界和连接表达较清楚，可作为辅助参考。
- ST Nucleo / Discovery 类 schematic：适合学习 MCU 最小系统、连接器、调试接口、BOOT/RESET/SWD 表达。

## 3. Page Structure

推荐页结构：

- P1 `SYSTEM_ARCHITECTURE`：系统边界、外部对象、电源流、主信号流、接口 contract。
- P2 `DETAIL`：元件级原理图、网表、BOM、PCB 约束、调试入口。
- Additional pages：只在复杂设计中按功能拆分，例如 Power、MCU、Analog Input、Connector。

## 4. System Architecture Page

架构页不是详细连线页。

必须表达：

- 外部系统。
- Board boundary。
- Power tree。
- Main signal chain。
- Connector / interface contract。
- Key timing/layout constraints。

推荐布局：

- 外部对象放板外，例如 sensors、host、power source。
- 板内模块放在明确边界框内。
- 电源流放上方。
- 主信号流放中间。
- 审查表放底部。

禁止：

- 把 API 操作规则写进原理图。
- 把权限、备份、脚本说明写进图纸正文。
- 用电气 `WIRE` 画非电气说明箭头。
- 用大量段落解释代替模块关系。

## 5. Detail Page

细节页负责真实电气连接。

要求：

- 元件和位号清楚。
- 网络名不压住引脚号、引脚名、器件本体。
- 同一线段上同名 net label 只保留一个。
- 重复通道几何一致。
- 电源、GND、复位、BOOT、SWD/UART、ADC 输入可审查。
- 关键约束放在相关电路附近或统一备注区。

## 6. What To Extract From Good Schematics

每次看样板，不只看电路是否连通，重点提取这些规则：

- 页结构：cover / block diagram / power / MCU / analog / connector 是否分层。
- 功能分区：每个电路块是否有明确标题、边界、留白。
- 读图方向：电源流、信号流、控制流是否一致。
- 网络标识：net label 是否远离芯片本体、引脚号、引脚名。
- 重复单元：通道间距、元件方向、标注位置是否统一。
- 约束表达：layout note、采样时序、bring-up note 是否放在相关模块附近。
- 审图入口：关键电源、复位、时钟、BOOT、调试口、连接器 pin contract 是否一眼可查。

## 7. Rules Converted To LCEDA Work

在 LCEDA 里执行时，按这些可量化规则落地：

- 同一线段同一网络只放一个 net label。
- net label 到芯片边界至少预留一个最长网络名宽度。
- 重复通道之间保留一致垂直间距，不为了省纸挤在一起。
- 电气连接线只表达电气连接，不用来画说明箭头或文档框图。
- 架构页只表达系统关系，细节页才放元件级连接。
- 半成品截图不进仓库；只有能作为正/反例学习的图才保留。

## 8. NTC Temperature Acquisition Example

5 路 NTC 采样页推荐表达：

- 左侧：5 路 NTC 输入，垂直重复排列。
- 中间：MCU / ADC，引脚和输入网络对齐。
- 右上：电源输入、LDO、模拟 rail filter。
- 右中或下方：host connector。
- 下方：SWD / bring-up。
- 备注区：ADC 等待时间、丢弃首样、平均稳定样本、UART pin contract。

采样约束示例：

```text
After switching ADC mux channel:
wait >= 5 * tau
discard first conversion
average settled readings
```

## 9. Layout Intent

原理图要把布局意图传给 PCB：

- NTC RC loop short.
- ADC capacitor close to ADC node.
- Analog rail quiet and locally decoupled.
- UART/digital edges away from analog sampling nodes.
- GND references clear and not visually ambiguous.

## 10. Acceptance

及格：

- 能生成 netlist。
- 能导入 PCB。
- 电气大体能工作。

好：

- 别人能顺着图理解系统。
- 关键网络、约束、接口方向清楚。

专业：

- 可用于设计评审、PCB 约束传递、bring-up、故障定位、BOM 管理、量产交接。

## 11. Public Repository Rule

官方公开参考设计可以保留为学习材料。若后续发现某个资料不允许再分发，应改为链接索引，并在本文记录来源和学习要点。


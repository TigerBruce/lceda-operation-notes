# LCEDA Pro AI Schematic Workflow Notes

这是一个面向公开复用的嘉立创 EDA 专业版 / EasyEDA Pro 操作记忆库。

目标不是保存某个具体工程的备份，而是沉淀一套可复用的方法：如何让 AI 通过 Run API Gateway 接管 EDA，安全整理原理图，验证网表，避免误改封装和工程文件。

## What To Read

- [docs/01-getting-started-and-safe-workflow.md](docs/01-getting-started-and-safe-workflow.md)  
  新手从零开始：安装 Run API Gateway、连接 EDA、第一次只读调用、安全写入、截图和网表验证。

- [docs/02-schematic-quality-and-reference-study.md](docs/02-schematic-quality-and-reference-study.md)  
  什么是优秀原理图，如何学习 TI / ST 等大厂样板，并转化成 LCEDA 排版规则。

- [docs/03-api-validation-notes.md](docs/03-api-validation-notes.md)  
  已实测 API、验证方法、失败路径、风险接口、版本相关坑。

## Reference Materials

- [原理图设计样板示例/](原理图设计样板示例/)  
  官方公开参考设计 PDF，用作原理图架构、分区、标注、审图方法的学习基准。

- [参考样板截图/](参考样板截图/)  
  从优秀样板中截取的局部参考图，用来快速对比可读性和分区表达。

## Public Repo Policy

这个仓库只保留对其他人有复用价值的内容。

不提交：

- 具体工程备份、`.epro/.epro2/.eprj2/.epru`。
- 原始源码导出、临时网表、BOM、DRC 中间文件。
- 大量过程截图。
- 半成品原理图截图。
- 本机绝对路径、账号、私有工程 UUID、投板工程源文件。

允许提交：

- 方法文档。
- 经过脱敏的实测结论。
- 小工具脚本。
- 官方公开参考设计样板资料。
- 从优秀样板中整理出的精选学习截图。

## Core Rules

1. Board / page targeting must use UUID and current document checks, not tab title guesses.
2. Never modify footprints/packages through API. Inspect and report only.
3. For official pages, prefer small whitelisted source edits over broad primitive loops.
4. After every schematic edit, verify netlist or key network counts.
5. Treat HTTP 500 as an unknown state: read back before retrying.
6. Screenshots are useful only after visual or pixel validation.

## Tool

`tools/Invoke-LcedaBaselineCapture.ps1` is kept as a reusable helper for capturing API state and screenshots. It should write artifacts outside the repo or into an ignored local output folder.

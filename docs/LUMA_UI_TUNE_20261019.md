# Luma 0.8.1 — 搜索栏与文件名微调（2026-10-19）

## 触发原因

用户查看 Luma 0.8.1 实际 930px 宽搜索界面，反馈搜索栏**高度略大、搜索栏输入字体略大、搜索结果文件名字体略大**。其他路径、日期、圆角、尺寸已经认可，保持不变。

## 精确变更

| QML | 原参数 | 新参数 | 效果 |
| --- | --- | --- | --- |
| `src/app/qml/SearchBar.qml` | 浮动搜索框 `Theme.headerHeight + 8` | `Theme.headerHeight + 4` | 默认 72 → 68px |
| `src/app/qml/SearchBar.qml` | 输入字体 `Theme.uiSearch + 4` | `Theme.uiSearch + 2` | 默认 28 → 26px |
| `src/app/qml/ResultRow.qml` | 文件名 `Theme.uiTitle + 2` | `Theme.uiTitle + 1` | 默认 20 → 19px |

只涉及两个 QML 文件、三行数值。没有修改公共 `Theme.uiSearch/uiTitle`，因此不会改变设置窗口、剪贴板等使用这些主题变量的其他组件。

## 不变项

主窗口宽 930px、Qt alpha 圆角 28px、路径日期字号、结果行高、分类标签、排序和操作栏、索引引擎、服务、MCP/插件、所有快捷键均不改变。

## 验证及回滚

- Qt 6.12 / MSVC Release 编译通过。
- Win10 本机隔离配置实测查询 `123`，截图 `D:\Luma-Toolchain\luma-0.8.1-font-tune.png`，窗口 930×608；原主窗口约 930×612（4px 差异符合顶部高度变化）。
- 全套 CTest：**13/13 通过**（128.98 秒，退出码 0）。
- 独立预览 ZIP：50,367,637 字节，92 项，CRC 校验正确；真实解压后通过 `START_PREVIEW.cmd` 唤起带窗口的进程，使用独立 profile，并正常退出。
- ZIP SHA-256：`2A4AB03FF9E394C35FCAFA3BEBEB318ADB0784419BE33D130ABC83FEBFC6E1FF`；同目录的 `.sha256` 文件可核对。
- 确认使用 `--background` 启动后，先 `--toggle` 唤出窗口，再 `--query 123` 填入搜索内容；这是当前隔离预览的稳定唤出顺序，前两次直接 `--query` 因隐藏窗口导致截图失败，未涉及程序改动。
- 独立预览：`D:\Luma\dist\Luma-0.8.1-search-typography-preview.zip`；不安装，不写入正式程序目录。
- Git 分支：`ui/search-typography-v081`，由 `main`（c335ca6）创建。v0.8.1 tag 与 Release 保持不变。

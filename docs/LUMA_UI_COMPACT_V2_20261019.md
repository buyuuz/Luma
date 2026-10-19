# Luma 搜索栏紧凑版 V2（2026-10-19）

## 原因

用户认为 64px 高、24px 输入字号、约 22px 搜索图标的顶部搜索栏仍偏大，要求再缩小一档。文件名、外框和其他组件已经认可，继续保持不变。

## 修改

只调整 `src/app/qml/SearchBar.qml` 三处，**不改 Theme 的全局尺寸**：

- 悬浮 Launcher 的顶部搜索栏从默认 `Theme.headerHeight=64` 改为 `Theme.headerHeight-4=60px`；`inTaskbarBox` 时保留原高度。
- Launcher 搜索输入字号由 `Theme.uiSearch=24` 改为 `Theme.uiSearch-2=22px`；任务栏内输入字体仍使用原值。
- 搜索图标由默认 `Theme.searchIconSize=22` 改为 `Math.max(18, Theme.searchIconSize-2)=20px`。仍根据系统的字体尺寸档位自适应。

**不变：** 文件名 19px、结果列表、路径/日期、930px 宽度、28px Qt 逐像素透明圆角、底部栏、服务、索引和快捷键。

## 测试 / 维护

- 基于 `ui/search-compact-v081`（f09729e）创建 `ui/search-compact-v2-v081`，正式 `main`、v0.8.1 Release 不更改。
- 使用 Qt 6.12 / MSVC Release 编译完成，退出码 0。
- 打包为 `D:\Luma\dist\Luma-0.8.1-search-compact-v2-preview.zip`，内置最新构建 EXE 和 `START_PREVIEW.cmd`，使用独立 `data` 配置目录。
- ZIP CRC 完整性检查、解压后 EXE 与 build SHA256 一致、实际启动与干净退出检查均通过。
- 完整 CTest：**13/13 组通过**，157.98 秒，退出码 0。
- 便携 ZIP：50,296,940 字节，91 个条目，SHA-256 `CD5C56D2F9BD1262A49FBD081FE70B512D84CE2CE13C6738B66BD924EC1548B5`，同目录有 `.sha256` 校验文件。
- 解压后从 `START_PREVIEW.cmd` 启动的主进程可见窗口句柄，使用独立 profile 且 `--quit` 正常退出；已安装的 Luma 后台服务继续运行。
- 尚未进行人工视觉验收；请用户解压查看实际顶部比例再决定是否进入正式版。

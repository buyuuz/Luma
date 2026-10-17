# Luma Raycast Balanced V7 (2026-10-17)

本轮只调整主搜索启动器的视觉比例，不修改搜索引擎、索引服务、权限或快捷键事件处理。

## 目标与实际代码

从已提交的 `ui/raycast-alpha-corners-v6`（8a74baf）建立新分支 `ui/raycast-balanced-v7`，保留 V6 Windows 10 逐像素 alpha 平滑圆角。

- 主窗口宽度：980 → **930px**。窗口高度仍按实际结果数量自动计算。
- 主窗口外圆角：22 → **28px**。使用独立 `Theme.launcherRadius`，**其他窗口依然保留 `Theme.windowRadius=22`**，避免其 Win32 原生裁切与 QML 描边不一致。
- 搜索字体：`Theme.uiSearch+2` → `+4`（标准模式 26 → **28px**）。
- 搜索顶部高度：`Theme.headerHeight +14` → `+8`（减少 6px）。
- 结果标题：`Theme.uiTitle` → `Theme.uiTitle+2`（标准 18 → **20px**）。
- 路径与日期：`Theme.uiCaption+1`（标准 14 → **15px**），结果标签字体同步 +1px。
- 单结果行：`Theme.rowHeight -4`（标准 60 → **56px**），只影响主搜索窗口。
- “搜索结果”标题栏：35 → **31px**，字体 +1px。
- 底部操作栏：58 → **52px**，文字 +1px；玻璃胶囊和快捷键标签稍微增大圆角。
- 右上角分类：字体 +1px，仅 `scaled` 主搜索模式。
- 文件名与路径之间间距 22 → 18px，文件名分配更符合缩窄后的窗口。
- Qt 绘制的主窗口主体与描边共享 `launcherRadius`，在 Windows 10 使用 Qt alpha 平滑边缘，不恢复 `SetWindowRgn` 硬裁切。

修改 `Theme.qml`、`Main.qml`、`SearchBar.qml`、`ResultRow.qml`、`ScopeTabs.qml`、`Footer.qml`、`WindowEdge.qml` 七个 QML 文件。

## 独立性与验证

- 正式 `main` 的 v0.8.0 Release 保持不动。
- 当前用户安装在 `C:\Program Files\Luma` 的版本保持不动。
- 多结果实机截图：`D:\Luma-Toolchain\luma-v7-balanced.png`，930×612。
- 少结果实机截图：`D:\Luma-Toolchain\luma-v7-balanced-single.png`，930×276。
- Qt6.12/MSVC Release 完整编译：已通过，退出码 0。
- 完整 CTest：**13/13 组通过**，总耗时 **124.30 秒**，退出码 0。
- 独立便携预览：`D:\Luma\dist\Luma-Raycast-v7-balanced-preview.zip`，50,425,032 字节，93 个 ZIP 项且 CRC 校验成功，包含多结果、少结果两张实机截图。
- SHA-256：`B7028B9110085D254DADAD9D33D298B95CD8A86670CC26517A914E10AF964605`，同目录 `.sha256` 可核对。
- ZIP 实际解压后 `START_PREVIEW.cmd` 启动成功，独立 profile 下使用 `--quit` 能正常退出（约 1 秒）；首次 3 秒退出检查不够稳定，复核后不存在持续占用进程。
- 正式版 `main`、v0.8.0 Release 和已安装的 Luma 后台服务未修改。

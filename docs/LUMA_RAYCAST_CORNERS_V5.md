# Luma Raycast V5 — Windows 10 四角修复

## 问题与依据

2026-10-16 用户反馈 V4 在仅有一条搜索结果时四角仍不自然。检查确认：
- 原生 Win10 `SetWindowRgn` 裁切与 QML `Theme.windowRadius=22` 同时存在；
- `Main.qml` 除根部圆角面板外，还在顶部单独绘制了 54px 高、半径 22px 的反光描边；
- `Footer.qml` 将**整个底栏**做成半径 22px 的圆角矩形，导致底栏上缘又出现两个独立圆角；
- `WindowEdge.qml` 直接贴紧 Win32 硬裁切边缘抗锯齿，叠加 Acrylic 时容易出现双重线与阴影差异。

## 修复内容

1. 保留现有原生 Win10 `SetWindowRgn` 外框及 22px 根圆角，移除顶部额外绘制的一套圆角反光框。
2. 底栏不再有独立的顶部圆角：仍有底部圆角的底栏背景，但其顶部用相同颜色的矩形填平，以免上方拼接出现弧线。
3. 只对主搜索窗口的 `WindowEdge` 内缩 1px，圆角半径相应减小 1px；其他界面仍使用原有描边值，减少 Qt 平滑边框与 Win32 像素硬裁切相互冲突。
4. 不改变索引服务、MCP、安全权限、搜索行为和快捷键。

## 验证

- Qt 6.12 + MSVC Release 编译成功；
- 已用隔离配置和 `112` 查询对实际 Windows 10 启动器截取 980×660 窗口图，确认顶部不再有独立圆角反光弧线，底栏连续衔接；
- 通过 Win32 `GetWindowRgn` 验证实际窗口的圆角区域，四个边角样点均被排除；窗口变高时会自动更新区域；
- 回归测试由 `D:\Luma-Toolchain\test-luma.cmd` 执行，**13/13 组通过**，总用时 107.59 秒。
- 独立 V5 预览 ZIP `D:\Luma\dist\Luma-Raycast-v5-corners-preview.zip` 已校验 ZIP CRC，解压后的 `START_PREVIEW.cmd` 启动/退出检查通过。
- ZIP SHA-256：`A0EA8F17210ED4F204B32420D2331A48A6E47F28B23F55188B26459DBF45289B`；稳定版 Luma 服务保持运行，没有被停用、重装或卸载。

## 限制

`SetWindowRgn` 仍属于像素级硬裁切，不具有 macOS 原生像素级透明柔边；在特定桌面合成器/缩放配置可能有轻微像素级边缘。要彻底获得 macOS 式的平滑逐像素 alpha 圆角，需要单独验证 Qt layered window 与 Win10 Acrylic 的兼容性，不能在本轮未经测试就替换原生裁切方案。

## 版本边界

- 正式 `main` 和 `v0.8.0` Release 不修改；
- 本轮 `ui/raycast-corners-v5` 来自 `ui/raycast-layout-v4`；
- 仅用于独立便携预览，不直接安装或替换稳定版。

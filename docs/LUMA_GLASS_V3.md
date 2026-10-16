# Luma Glass V3 — 视觉设计与维护记录

## 目标

根据 2026-10-16 确认的 macOS / Raycast 深色玻璃参考图，改善搜索主窗口的视觉气质；不调整搜索索引、快捷键映射、插件数据或后台服务。UI 先独立于正式的 `main` 分支。

## 本轮设计决策

- **窗口材质**：由深蓝实色改为偏中性的石墨黑渐变。在 Windows 10 中优先尝试系统 Acrylic 模糊（动态检测 `SetWindowCompositionAttribute`），不支持则沿用 QML 背景；不使用全屏实时 Shader。仅针对 Launcher 窗口。
- **窗口圆角**：保留 Win10 的 Win32 区域裁切方式，外圆角与 QML 的 22px 保持一致。窗口尺寸变化时重新设置区域。
- **搜索头部**：去除沉重的输入框描边，保留分类切换、文本输入、输入法、鼠标拖动、当前搜索类型。
- **结果列表**：灰色玻璃态选中、柔和悬停、淡化背景按钮。隐藏遮挡文件图标的 `Ctrl+1` 提示**仅为视觉隐藏**，键盘快捷键功能未修改。
- **底部工具条**：精简为主要 Enter 提示，其余快捷键继续在帮助菜单可查。结果排序、历史切换及其操作保持不变。
- **颜色**：搜索 Launcher 的玻璃文字和键帽明确使用深色背景配色，不受 Windows 当前深浅色主题影响；避免 LTSC 浅色模式下的白键帽和低对比度问题。

## 涉及文件

`src/app/qml/{Main,Theme,SearchBar,ScopeTabs,ResultRow,Footer,KeyHint,RowAction}.qml` 及 `src/app/platform/WindowEffects.{h,cpp}`、`src/app/App.cpp`。

## 测试 / 回滚

- 构建：`D:\Luma-Toolchain\build-luma.cmd`
- 自动测试：`D:\Luma-Toolchain\test-luma.cmd`
- 主窗口隔离启动：`Luma.exe --profile D:\Luma-Toolchain\SmokeProfile --query 112`
- 原始正式源码：GitHub `main`、Release `v0.8.0`，均不覆盖。
- 本轮分支：`ui/luma-glass-v3`。尚需用户亲自查看视觉效果，再决定是否进一步开发。

## 验证结果（2026-10-16）

- Qt 6.12/MSVC Release 完整编译：通过。
- CTest 13/13 组：通过（108.24 秒，退出码 0）。
- Windows 10 LTSC 隔离 profile 下真实搜索窗口运行及截图：通过，窗口 760x595，外圆角有效。
- 独立预览包：D:\Luma\dist\Luma-MacGlass-v3-preview.zip，ZIP 校验通过。
- 现有 C:\Program Files\Luma 安装版以及 LocalSystem 后台服务均未操作。

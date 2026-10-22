# Luma 上游更新与版本维护

## 三条独立来源

| 位置 | 用途 | 是否自动替换本地程序 |
| --- | --- | --- |
| `origin/main` → [buyuuz/Luma](https://github.com/buyuuz/Luma) | Luma 正式源码：Luma 品牌、服务与路径、Qt UI、权限修复 | **不会** |
| `upstream/main` → [LingCore/WinShun](https://github.com/LingCore/WinShun) | 仅用于比对上游功能修复、新版本与新增模块 | **不会** |
| Luma [Releases](https://github.com/buyuuz/Luma/releases) | 用户手动下载、安装 Luma 正式版本 | **不会静默安装** |

WinShun 更新不能直接替换 Luma 的 EXE 或安装目录。Luma 的客户端更新检查只访问 `buyuuz/Luma` Releases；弹出提醒并打开 GitHub 发布页，需要手动下载并安装。内部兼容变量如 `WINSHUN_UPDATE_FEED`、QML import `WinShun`、某些 CMake target 名称保持不变，避免破坏功能。

## 当前基线（2026-10-17）

- Luma v0.8.0：第一版正式发布，可从 Releases 回退。
- Luma v0.8.1：接受 V7 Raycast 界面、930px 宽、28px alpha 圆角、更醒目的文字，UI 位于 `ui/raycast-balanced-v7` 的演进提交。Luma 品牌、原有 Win10 服务、MCP 安全策略保持不变。
- 上游 WinShun 已发布 **0.12.0**（2026-10-22 检查时 `4d62a68`）：相较当前 Luma `main` 有 **125 个待评估提交**、**416 个上游变更文件**，其中 **103 个文件**也有 Luma 定制改动（包含 19 个 QML 文件）。**尚未合并**。0.12.0 包含截图标注与再编辑、无管理员权限的按用户安装、鼠标动作设置、剪贴板清理和新的搜索排序等功能。上述数字只是检查时快照，后续请以 `scripts/check-upstream.ps1` 的实时结果为准。与 Luma 版本号不同步是有意的：只有经审核并通过测试才引入上游代码。
- 原作者 MIT 许可和版权声明保留。

## 检查上游（不会修改产品源码）

打开 PowerShell 并进入项目：

```powershell
cd D:\Luma
.\scripts\check-upstream.ps1
```

脚本验证 `upstream` URL，拉取 `upstream/main` 的引用，输出上游新提交、文件列表、与 Luma 自定义文件交集；**不合并、不重基、不打包、不发布、不安装**。

只准备一个本地审核分支，不合并代码：

```powershell
.\scripts\check-upstream.ps1 -Prepare
git branch --list "sync/*"
```

需要创建审核分支时，工作区必须无修改。脚本只在本地创建 `sync/winshun-日期时间`，不会推送到 GitHub，不会改变当前分支。

## 真正同步更新的步骤（每次单独实施）

1. 确认上游发布内容与安全记录。必要时先备份当前正式安装包、源码 commit 和用户配置目录。
2. 执行 `check-upstream.ps1 -Prepare`。切换到新建的 `sync/winshun-*` 分支（不要直接在 `main` 操作）。
3. **人工审核提交**：逐个挑选需要的上游修复（`git cherry-pick <sha>`），或评估完整合并（`git merge --no-ff upstream/main`）。遇到冲突先处理；不可把上游同名文件覆盖整个 Luma 文件。
4. 对照《必须保留的本地契约》清单检查文件内容；尤其留意 Git 文本合并没有报错、但运行语义变化的情况。
5. 重新配置编译，运行 CTest 全套、Win10 实机 UI、索引服务、便携启动、安装覆盖升级和卸载测试。
6. 审核 UI 截图、品牌、设置保留、服务路径与启动后，再合并回 `main`；单独更新 Luma 版本号与发布说明，生成安装器 / ZIP / SHA256。
7. 经确认发布到 **buyuuz/Luma**；上游变更不能触发自动发布或自动安装。

## 必须保留的本地契约

- `CMakeLists.txt` 中 Luma 版本号、`scripts/release.ps1` 目标必须是 `buyuuz/Luma`，不能改为 `LingCore/WinShun`。
- `installer/WinShun.iss` 的 Luma **AppId 必须稳定不变**；安装目录仍为 Luma；升级时要能识别旧安装，避免重复服务。
- Luma.exe / LumaService.exe / 其他服务与管道名称、Explorer shell 扩展和任务栏挂接行为应完整保留，除非经兼容性迁移。
- `src/app/Updater.h` 的 kRepository = `buyuuz/Luma`，仅在新 Luma Release 发布后提醒下载。
- `src/app/qml/` 的 Raycast 界面（V7：930px、28px、字体、底栏、结果单行）与 Windows 10 `QQuickWindow` 逐像素 alpha 圆角。
- MCP 权限默认值、插件与数据目录、便携模式数据保留逻辑，不能因上游直接覆盖而退化。
- `LICENSE` 原作者 MIT 保留，文档注明派生自 WinShun。

## 发布和回滚

- 优先使用 `scripts/build.ps1`、`scripts/release.ps1`；**禁止**未经审核直接调用 `release.ps1 -Publish`。
- 不要复用已发布的 tag；每次发布更新独立版本号、说明、SHA256。
- 回退可以重新安装旧 Luma 安装包，**不要删除用户数据和索引**；遇到数据库结构升级，必须先确认旧版本是否支持，否则应当用备份恢复。
- 如果上游同步较复杂，就先留在 `sync/*`，让当前稳定 Luma 照常可用。

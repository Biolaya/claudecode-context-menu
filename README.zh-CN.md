# Claude Code Windows 右键菜单

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE.svg)
![No Admin](https://img.shields.io/badge/admin-not%20required-success.svg)

[English](./README.md)

为 Windows 文件资源管理器添加一个右键菜单项，让你可以直接在选中的目录中启动 Claude Code。它替代了反复手动打开终端、执行 `cd <folder>`、再执行 `claude` 的流程。

## 功能介绍

- 在“右键文件夹”菜单中添加 `Open Claude Code here`。
- 在“文件夹内部空白处右键”菜单中添加同样入口。
- 支持右键磁盘根目录，例如 `C:\`、移动硬盘或挂载盘。
- 自动在目标目录中启动 Claude Code。
- 如果系统安装了 Windows Terminal（`wt.exe`），优先使用 Windows Terminal；否则回退到 Windows PowerShell。
- 只安装到当前 Windows 用户，写入 `HKCU`。
- 支持带空格、中文和常见特殊字符的路径。
- 安装和卸载脚本支持 `-WhatIf`、`-Confirm` 和 `-Force`。

## 环境要求

- Windows 10 或更高版本。
- Windows PowerShell 5.1 或更高版本。
- Claude Code CLI 已安装，并且可以在当前用户 PATH 中通过 `claude` 命令访问。
- Windows Terminal 是可选项。

先确认 Claude Code 可用：

```powershell
Get-Command claude
claude
```

## 安装

下载或克隆本仓库，然后在项目目录中打开 PowerShell。

预览将要执行的操作：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1 -Force -WhatIf
```

安装：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1
```

非交互安装：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1 -Force
```

安装脚本会把仓库中的源启动器：

```text
.\Open-ClaudeCode.ps1
```

复制到实际安装位置：

```text
%LOCALAPPDATA%\ClaudeCodeContextMenu\Open-ClaudeCode.ps1
```

并写入这些当前用户注册表项：

- `HKCU:\Software\Classes\Directory\shell\ClaudeCode`
- `HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode`
- `HKCU:\Software\Classes\Drive\shell\ClaudeCode`

## 使用方式

安装后可以这样使用：

- 右键某个文件夹，选择 `Open Claude Code here`。
- 打开某个文件夹，在空白处右键，选择 `Open Claude Code here`。
- 右键某个磁盘根目录，选择 `Open Claude Code here`。

启动器会在目标目录中打开终端，并执行：

```powershell
claude
```

## 工作原理

1. 文件资源管理器通过 `%1` 传入被右键选中的文件夹路径，或通过 `%V` 传入当前文件夹空白处路径。
2. 注册表命令使用 Windows PowerShell 启动已安装的 helper。
3. helper 校验目标路径必须是文件系统目录。
4. 如果 Windows Terminal 可用，helper 执行 `wt.exe -d <目标目录>`，再启动 PowerShell 运行 `claude`。
5. 如果 Windows Terminal 不可用或立即启动失败，helper 会直接用 Windows PowerShell 在目标目录中运行 `claude`。

注册表命令只在从资源管理器启动 helper 时使用 `ExecutionPolicy Bypass`。真正运行 `claude` 的终端不会使用 `ExecutionPolicy Bypass`。

## 卸载

预览卸载：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1 -Force -WhatIf
```

卸载：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1
```

卸载脚本会删除已知注册表项和已知安装文件。只有当安装目录为空时，才会删除该目录。

## Windows 11 说明

本项目使用经典的当前用户注册表右键菜单项。在 Windows 10 上，它会显示在经典右键菜单中。在 Windows 11 上，它可能出现在 **Show more options** / “显示更多选项” 或 `Shift+F10` 菜单中。

如果要进入 Windows 11 第一层现代右键菜单，通常需要打包应用或 COM `IExplorerCommand` 形式的 Shell 扩展；这超出了本轻量脚本工具的范围。

## 故障排查

如果右键菜单出现了，但 Claude Code 没有启动：

- 在 PowerShell 中运行 `Get-Command claude`，确认命令可以解析。
- 在普通 PowerShell 窗口中先运行一次 `claude`，确认 Claude Code 本身可用。
- 如果刚安装 Claude Code，重启文件资源管理器，或注销后重新登录，让 Explorer 获取最新 PATH。
- 使用 `-Force` 重新运行安装脚本。
- 确认 helper 存在于 `%LOCALAPPDATA%\ClaudeCodeContextMenu\Open-ClaudeCode.ps1`。
- Windows 11 用户请检查 **Show more options** / “显示更多选项”。

查看已安装的注册表命令：

```powershell
Get-Item 'HKCU:\Software\Classes\Directory\shell\ClaudeCode\command'
Get-Item 'HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode\command'
Get-Item 'HKCU:\Software\Classes\Drive\shell\ClaudeCode\command'
```

## 安全说明

- 安装脚本只写入当前用户注册表。
- 不需要管理员权限。
- 启动器会在运行时从当前用户 PATH 中解析 `claude`。这样升级 Claude Code 更简单，但也意味着你的 PATH 应该是可信的。
- 已安装的 helper 位于 `%LOCALAPPDATA%\ClaudeCodeContextMenu`。

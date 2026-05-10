# Claude Code Windows 右键菜单

[English](./README.md)

为 Windows 文件资源管理器添加一个名为 `Claude Code` 的右键菜单项，让你可以直接在右键选中的目录中启动 Claude Code。

## 功能介绍

- 在“右键某个文件夹”的菜单中添加 `Claude Code`。
- 在“文件夹内部空白处右键”的菜单中添加 `Claude Code`。
- 自动在目标目录中启动 Claude Code，替代手动执行 `cd <folder>` 再执行 `claude` 的流程。
- 如果系统安装了 Windows Terminal（`wt.exe`），优先使用 Windows Terminal。
- 如果没有安装 Windows Terminal，自动回退到 Windows PowerShell。
- 仅安装到当前 Windows 用户，不影响其他用户。
- 支持带空格、中文和常见特殊字符的路径。
- 提供卸载脚本，可移除右键菜单项和 helper 脚本。

## 环境要求

- Windows 10 或更高版本。
- Claude Code CLI 已安装，并且可以在当前用户 PATH 中通过 `claude` 命令访问。
- Windows PowerShell。Windows Terminal 是可选项。

## 安装

在本项目目录中打开 PowerShell，然后运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1
```

安装脚本会把 `Open-ClaudeCode.ps1` 复制到 `%LOCALAPPDATA%\ClaudeCodeContextMenu\`，并写入两个当前用户注册表项：

- `HKCU:\Software\Classes\Directory\shell\ClaudeCode`
- `HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode`

**参数：**

- `-Force` — 跳过所有提示（例如 claude 未在 PATH 中时）。
- `-WhatIf` — 预览将要执行的操作，不实际修改系统。

## 使用方式

安装后，在文件资源管理器中可以这样使用：

- 右键某个文件夹，然后选择 `Claude Code`。
- 打开某个文件夹，在空白处右键，然后选择 `Claude Code`。

启动器会在目标目录中打开终端，并执行：

```powershell
claude
```

## 卸载

运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1
```

卸载脚本会删除 `Claude Code` 右键菜单项，并移除 `%LOCALAPPDATA%` 下的 helper 目录。

**参数：**

- `-Force` — 跳过确认提示。

## 注意事项

- 安装不需要管理员权限，因为脚本只写入 `HKCU`。
- 在 Windows 10 上，菜单项会直接显示在经典右键菜单中。
- 在 Windows 11 上，标准注册表右键菜单项可能会出现在“显示更多选项”中。
- 脚本不会硬编码 Claude Code 的安装路径，而是在启动时从当前用户 PATH 中解析 `claude` 命令。

## 故障排查

如果右键菜单出现了，但 Claude Code 没有启动：

- 先确认在普通 PowerShell 窗口中执行 `claude` 是否可用。
- 安装或更新 Claude Code 后，重新运行安装脚本。
- 确认 PATH 中包含 `claude` 命令所在目录。

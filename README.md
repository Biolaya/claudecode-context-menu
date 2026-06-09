# Claude Code Windows Context Menu

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE.svg)
![No Admin](https://img.shields.io/badge/admin-not%20required-success.svg)

[中文说明](./README.zh-CN.md)

Add a Windows File Explorer context menu entry that opens Claude Code directly in the selected directory. It replaces the repeated manual flow of opening a terminal, running `cd <folder>`, and then running `claude`.

## Features

- Adds `Open Claude Code here` to folder right-click menus.
- Adds the same entry to folder background right-click menus.
- Adds support for drive root right-click menus, such as `C:\` or removable drives.
- Starts Claude Code in the selected/current directory.
- Prefers Windows Terminal (`wt.exe`) when available, then falls back to Windows PowerShell.
- Installs only for the current Windows user under `HKCU`.
- Supports paths with spaces, Chinese characters, and common special characters.
- Includes `-WhatIf`, `-Confirm`, and `-Force` support for safer install and uninstall flows.

## Requirements

- Windows 10 or later.
- Windows PowerShell 5.1 or later.
- Claude Code CLI available as `claude` in your user PATH.
- Windows Terminal is optional.

Verify Claude Code first:

```powershell
Get-Command claude
claude
```

## Install

Download or clone this repository, then open PowerShell in the project folder.

Preview the changes:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1 -Force -WhatIf
```

Install:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1
```

For non-interactive install:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1 -Force
```

The installer copies the source launcher:

```text
.\Open-ClaudeCode.ps1
```

to the installed helper path:

```text
%LOCALAPPDATA%\ClaudeCodeContextMenu\Open-ClaudeCode.ps1
```

It writes these current-user registry entries:

- `HKCU:\Software\Classes\Directory\shell\ClaudeCode`
- `HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode`
- `HKCU:\Software\Classes\Drive\shell\ClaudeCode`

## Usage

After installation:

- Right-click a folder and choose `Open Claude Code here`.
- Open a folder, right-click empty space, and choose `Open Claude Code here`.
- Right-click a drive root and choose `Open Claude Code here`.

The launcher opens a terminal in that directory and runs:

```powershell
claude
```

## How It Works

1. File Explorer passes the selected folder path through `%1` or the current folder background path through `%V`.
2. The registry command starts the installed helper with Windows PowerShell.
3. The helper validates that the target is a filesystem directory.
4. If Windows Terminal is available, the helper runs `wt.exe -d <target>` and starts PowerShell with `claude`.
5. If Windows Terminal is unavailable or fails immediately, the helper starts Windows PowerShell directly with the target directory as its working directory.

The registry command uses `ExecutionPolicy Bypass` only to run the installed helper from Explorer. The terminal that runs `claude` does not use `ExecutionPolicy Bypass`.

## Uninstall

Preview uninstall:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1 -Force -WhatIf
```

Uninstall:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1
```

The uninstaller removes the known registry entries and known installed files. It removes the install directory only if it is empty.

## Windows 11 Note

This project uses classic current-user registry context menu entries. On Windows 10 they appear in the classic right-click menu. On Windows 11 they may appear under **Show more options** or `Shift+F10`.

First-level Windows 11 context menu integration requires a packaged shell extension or COM-based `IExplorerCommand`, which is intentionally out of scope for this lightweight script-based utility.

## Troubleshooting

If the menu appears but Claude Code does not start:

- Run `Get-Command claude` in PowerShell and confirm it resolves.
- Run `claude` in a normal PowerShell window before using the context menu.
- If Claude Code was installed recently, restart File Explorer or sign out and back in so Explorer sees the updated PATH.
- Re-run the installer with `-Force`.
- Confirm the helper exists at `%LOCALAPPDATA%\ClaudeCodeContextMenu\Open-ClaudeCode.ps1`.
- On Windows 11, check **Show more options**.

To inspect installed registry commands:

```powershell
Get-Item 'HKCU:\Software\Classes\Directory\shell\ClaudeCode\command'
Get-Item 'HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode\command'
Get-Item 'HKCU:\Software\Classes\Drive\shell\ClaudeCode\command'
```

## Security Notes

- The installer writes only to the current user's registry hive.
- No administrator permission is required.
- The launcher resolves `claude` from the current user's PATH at launch time. This keeps updates simple, but it also means your PATH should be trusted.
- The installed helper lives under `%LOCALAPPDATA%\ClaudeCodeContextMenu`.

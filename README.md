# Claude Code Windows Context Menu

[中文说明](./README.zh-CN.md)

Add a Windows File Explorer context menu entry named `Claude Code` so you can open Claude Code directly in the folder you right-clicked.

## Features

- Adds `Claude Code` to the right-click menu for folders.
- Adds `Claude Code` to the right-click menu for empty space inside a folder.
- Starts Claude Code in the selected/current directory, replacing the manual `cd <folder>` then `claude` workflow.
- Prefers Windows Terminal (`wt.exe`) when available.
- Falls back to Windows PowerShell when Windows Terminal is not installed.
- Installs only for the current Windows user.
- Supports paths with spaces, Chinese characters, and other common special characters.
- Includes an uninstall script that removes the registry entries and helper script.

## Requirements

- Windows 10 or later.
- Claude Code CLI available as `claude` in your user PATH.
- Windows PowerShell. Windows Terminal is optional.

## Install

Open PowerShell in this project folder and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1
```

The installer writes two current-user registry entries:

- `HKCU:\Software\Classes\Directory\shell\ClaudeCode`
- `HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode`

It also installs the launcher helper to:

```text
%LOCALAPPDATA%\ClaudeCodeContextMenu\Open-ClaudeCode.ps1
```

## Usage

After installation, use either entry in File Explorer:

- Right-click a folder, then choose `Claude Code`.
- Open a folder, right-click empty space, then choose `Claude Code`.

The launcher opens a terminal in that directory and runs:

```powershell
claude
```

## Uninstall

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1
```

This removes the `Claude Code` context menu entries and deletes the helper folder under `%LOCALAPPDATA%`.

## Notes

- No administrator permission is required because the installer writes to `HKCU`.
- On Windows 10, the menu item appears directly in the classic right-click menu.
- On Windows 11, standard registry context menu entries may appear under "Show more options".
- The script does not hard-code the path to Claude Code. It resolves `claude` from your current user PATH when launched.

## Troubleshooting

If the menu appears but Claude Code does not start:

- Confirm `claude` works in a normal PowerShell window.
- Re-run the installer after installing or updating Claude Code.
- Make sure your PATH includes the directory that contains the `claude` command.

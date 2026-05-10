# Claude Code Windows Context Menu

Adds a current-user Windows context menu item named `Claude Code`.

## Install

Run in PowerShell from this folder:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1
```

After installation:

- Right-click a folder and choose `Claude Code` to run `claude` in that folder.
- Right-click empty space inside a folder and choose `Claude Code` to run `claude` in the current folder.

The launcher prefers Windows Terminal (`wt.exe`) when available and falls back to Windows PowerShell.

## Uninstall

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1
```

The scripts write only to the current user's registry hive under `HKCU:\Software\Classes` and install the helper script to `%LOCALAPPDATA%\ClaudeCodeContextMenu`.

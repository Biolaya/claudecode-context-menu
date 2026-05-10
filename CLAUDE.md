# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A Windows context menu installer that adds a "Claude Code" entry to File Explorer's right-click menu, so users can launch Claude Code directly in any folder.

## Files

- `install-claudecode-context-menu.ps1` — Main installer. Creates two `HKCU` registry entries (`Directory\shell\ClaudeCode` and `Directory\Background\shell\ClaudeCode`) and writes a launcher helper to `%LOCALAPPDATA%\ClaudeCodeContextMenu\Open-ClaudeCode.ps1`. The helper prefers Windows Terminal (`wt.exe`) and falls back to PowerShell.
- `uninstall-claudecode-context-menu.ps1` — Removes both registry entries and deletes the helper directory.

## How the launcher works

The registry entries invoke PowerShell with the helper script path and a placeholder (`%1` for folders, `%V` for background). The helper script:
1. Resolves the target directory from the placeholder argument.
2. Checks if `wt.exe` is available; if so, opens Windows Terminal in the directory and runs `claude`.
3. Otherwise opens `powershell.exe` with working directory set to the target and runs `claude`.
4. On failure, shows a WPF error dialog.

Arguments are quoted with a custom implementation that handles backslash-escaping before double quotes, as required by Windows command-line parsing.

## Key details

- No admin rights needed — registry writes go to `HKCU`.
- `claude` is resolved from PATH at launch time, never hard-coded.
- The helper script uses UTF-8 encoding (important: the file uses Chinese characters in error messages — see README.zh-CN.md).
- On Windows 11, the menu entry appears under "Show more options" (the classic right-click menu shim).

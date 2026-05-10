# Claude Code Context Menu Optimization Design

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish the existing Windows context menu installer with pre-flight checks, separate helper script, parameterized scripts, and clearer user feedback — without introducing compiled dependencies.

**Architecture:** Extract the embedded 100-line launcher script from the installer into a standalone `Open-ClaudeCode.ps1` file. The installer becomes a thin orchestrator: copy the helper, write registry entries, report results. Both install and uninstall scripts gain parameter support (`-Force`, `-WhatIf`).

**Tech Stack:** Windows PowerShell 5.1, HKCU registry, Windows Terminal (`wt.exe`)

---

## File Structure

```
Before:                          After:
├── install-...ps1  (150 lines)  ├── install-...ps1  (~60 lines)
│   (含 100 行嵌入 here-string)   ├── Open-ClaudeCode.ps1 (~110 lines, extracted)
├── uninstall-...ps1 (20 lines)  ├── uninstall-...ps1 (~35 lines)
├── README.md                    ├── README.md (updated)
├── README.zh-CN.md              └── README.zh-CN.md (updated)
```

## Component Design

### Open-ClaudeCode.ps1 (extracted launcher)

Extracted verbatim from the installer's here-string. Content unchanged except for one improvement:
- Better error message when `$TargetDirectory` is empty or the placeholder was not expanded by the shell (currently throws a generic exception).

Key elements preserved:
- `Quote-CommandLineArgument` — required because PowerShell 5.1 `Start-Process -ArgumentList` with an array does not handle double-quote/backslash escaping correctly.
- `Join-CommandLineArguments` — joins individually quoted args with spaces.
- Main logic: resolve directory → prefer `wt.exe` → fallback to `powershell.exe` → WPF error dialog on failure.
- UTF-8 encoding (Chinese characters used in error messages).

### install-claudecode-context-menu.ps1 (rewritten)

**Parameters:**
```powershell
param(
    [switch] $Force,
    [switch] $WhatIf
)
```

**Behavior:**
1. Copy `$PSScriptRoot\Open-ClaudeCode.ps1` to `%LOCALAPPDATA%\ClaudeCodeContextMenu\` (instead of generating from here-string).
2. Pre-flight: run `Get-Command claude -ErrorAction SilentlyContinue`. If not found, emit `Write-Warning` and (unless `-Force`) ask whether to continue.
3. Write two `HKCU` registry entries (`Directory\shell\ClaudeCode` and `Directory\Background\shell\ClaudeCode`), plus an additional `Version` string value for future upgrade detection.
4. `-WhatIf` mode: print what would be done without doing it.
5. On completion: print summary (menu name, helper path, version, Windows 11 note).

### uninstall-claudecode-context-menu.ps1 (enhanced)

**Parameters:**
```powershell
param(
    [switch] $Force
)
```

**Behavior:**
1. Unless `-Force`, prompt with `Read-Host "确定要移除 Claude Code 右键菜单吗？(y/N)"`. Exit on non-y response.
2. Remove both registry entries (skip with message if absent).
3. Remove `%LOCALAPPDATA%\ClaudeCodeContextMenu` directory.
4. Print summary of what was removed.

### README.md / README.zh-CN.md (updated)

Reflect the new file structure. Document `-Force` and `-WhatIf` parameters. Update the installation command examples.

## Key Constraints

- No admin rights — all registry writes go to `HKCU`.
- No compiled code (no COM DLL for Windows 11 first-level menu).
- `claude` resolved from PATH at runtime, not hard-coded.
- Maintains backward compatibility: existing installations can be overwritten by re-running the installer.

## Error Handling

- Helper script: WPF `MessageBox` on failure (existing behavior, preserved).
- Installer: `$ErrorActionPreference = 'Stop'`, wrapped in try/catch with clear messages.
- Uninstaller: non-destructive when registry entries are already absent.

## Testing

Manual verification on Windows:
1. Run install with `-WhatIf` — verify output lists expected actions.
2. Run install — verify context menu appears.
3. Right-click a folder → `Claude Code` — verify terminal opens in correct directory.
4. Right-click empty space in folder → `Claude Code` — same verification.
5. Test with a path containing spaces and Chinese characters.
6. Run uninstall — verify menu entries are gone.
7. Run uninstall again — verify it handles already-absent entries.

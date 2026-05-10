# Context Menu Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish the existing Windows context menu installer with pre-flight checks, separate helper script, parameterized scripts, and clearer user feedback.

**Architecture:** Extract the embedded 100-line launcher script from the installer into a standalone `Open-ClaudeCode.ps1`. The installer becomes a thin orchestrator: copy helper, write registry entries, report results. Both scripts gain parameter support (`-Force`, `-WhatIf`).

**Tech Stack:** Windows PowerShell 5.1, HKCU registry, Windows Terminal (`wt.exe`)

---

### Task 1: Create Open-ClaudeCode.ps1

**Files:**
- Create: `Open-ClaudeCode.ps1`
- Modify: N/A (installer updated in Task 2)

- [ ] **Step 1: Write Open-ClaudeCode.ps1**

```powershell
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $TargetDirectory
)

$ErrorActionPreference = 'Stop'

# PowerShell 5.1's Start-Process -ArgumentList with an array does not handle
# double-quote/backslash escaping correctly, so we build the command-line string
# ourselves following Windows command-line parsing rules.
function Quote-CommandLineArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    if ($Value.Length -eq 0) {
        return '""'
    }

    if ($Value -notmatch '[\s"]') {
        return $Value
    }

    $quoted = '"'
    $backslashCount = 0

    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') {
            $backslashCount++
            continue
        }

        if ($character -eq '"') {
            $quoted += '\' * (($backslashCount * 2) + 1)
            $quoted += '"'
            $backslashCount = 0
            continue
        }

        if ($backslashCount -gt 0) {
            $quoted += '\' * $backslashCount
            $backslashCount = 0
        }

        $quoted += $character
    }

    if ($backslashCount -gt 0) {
        $quoted += '\' * ($backslashCount * 2)
    }

    $quoted += '"'
    return $quoted
}

function Join-CommandLineArguments {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    return ($Arguments | ForEach-Object { Quote-CommandLineArgument -Value $_ }) -join ' '
}

try {
    if (-not $TargetDirectory -or $TargetDirectory -eq '%1' -or $TargetDirectory -eq '%V') {
        throw "This script is launched from the Claude Code context menu and expects a folder path. Run it by right-clicking a folder in File Explorer."
    }

    $target = Get-Item -LiteralPath $TargetDirectory -ErrorAction Stop

    if (-not $target.PSIsContainer) {
        throw "Target path is not a directory: $TargetDirectory"
    }

    $directory = $target.FullName

    $wt = Get-Command wt.exe -ErrorAction SilentlyContinue

    if ($wt) {
        $wtArguments = Join-CommandLineArguments -Arguments @(
            '-d'
            $directory
            'powershell.exe'
            '-NoExit'
            '-NoProfile'
            '-ExecutionPolicy'
            'Bypass'
            '-Command'
            'claude'
        )

        Start-Process -FilePath $wt.Source -ArgumentList $wtArguments
        exit 0
    }

    $powershellArguments = Join-CommandLineArguments -Arguments @(
        '-NoExit'
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-Command'
        'claude'
    )

    Start-Process -FilePath 'powershell.exe' -WorkingDirectory $directory -ArgumentList $powershellArguments
} catch {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        $_.Exception.Message,
        'Claude Code',
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit 1
}
```

- [ ] **Step 2: Verify PowerShell syntax**

Run:
```powershell
$errors = [System.Management.Automation.Language.Parser]::ParseFile(
    "$PSScriptRoot\Open-ClaudeCode.ps1",
    [ref]$null,
    [ref]$null
)
if ($errors.Count -eq 0) { Write-Host "PASS: No syntax errors" } else { Write-Host "FAIL: $($errors.Count) errors" }
```

Expected: `PASS: No syntax errors`

- [ ] **Step 3: Commit**

```bash
git add Open-ClaudeCode.ps1
git commit -m "feat: extract launcher script to standalone Open-ClaudeCode.ps1"
```

---

### Task 2: Rewrite install-claudecode-context-menu.ps1

**Files:**
- Modify: `install-claudecode-context-menu.ps1` (full rewrite)

- [ ] **Step 1: Write the new installer**

```powershell
param(
    [switch] $Force,
    [switch] $WhatIf
)

$ErrorActionPreference = 'Stop'

$menuName = 'Claude Code'
$version = '2.0'
$appDir = Join-Path $env:LOCALAPPDATA 'ClaudeCodeContextMenu'
$helperPath = Join-Path $appDir 'Open-ClaudeCode.ps1'
$sourceHelper = Join-Path $PSScriptRoot 'Open-ClaudeCode.ps1'

# Pre-flight: check claude availability
$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
    Write-Warning "claude.exe was not found in your PATH. The context menu will be installed but will not work until Claude Code is installed and available as 'claude'."
    if (-not $Force) {
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            Write-Host "Installation cancelled."
            exit 0
        }
    }
}

# Copy helper script
if ($WhatIf) {
    Write-Host "WhatIf: Copy $sourceHelper -> $helperPath"
} else {
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
    Copy-Item -LiteralPath $sourceHelper -Destination $helperPath -Force
    Write-Host "Copied launcher to: $helperPath"
}

$entries = @(
    @{
        Path = 'HKCU:\Software\Classes\Directory\shell\ClaudeCode'
        Placeholder = '%1'
    }
    @{
        Path = 'HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode'
        Placeholder = '%V'
    }
)

foreach ($entry in $entries) {
    $shellPath = $entry.Path
    $commandPath = Join-Path $shellPath 'command'
    $command = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $helperPath + '" "' + $entry.Placeholder + '"'

    if ($WhatIf) {
        Write-Host "WhatIf: New-Item -Path $shellPath"
        Write-Host "WhatIf: Set-Item -Path $shellPath -Value '$menuName'"
        Write-Host "WhatIf: New-ItemProperty -Path $shellPath -Name 'Icon' -Value 'powershell.exe'"
        Write-Host "WhatIf: New-Item -Path $commandPath"
        Write-Host "WhatIf: Set-Item -Path $commandPath -Value '<command>'"
        Write-Host "WhatIf: New-ItemProperty -Path $shellPath -Name 'Version' -Value '$version'"
        continue
    }

    New-Item -Path $shellPath -Force | Out-Null
    Set-Item -Path $shellPath -Value $menuName
    New-ItemProperty -Path $shellPath -Name 'Icon' -Value 'powershell.exe' -PropertyType String -Force | Out-Null

    New-Item -Path $commandPath -Force | Out-Null
    Set-Item -Path $commandPath -Value $command

    New-ItemProperty -Path $shellPath -Name 'Version' -Value $version -PropertyType String -Force | Out-Null
}

if (-not $WhatIf) {
    Write-Host ""
    Write-Host "Installed '$menuName' context menu (v$version)."
    Write-Host "  Helper: $helperPath"
    Write-Host "  Entries:"
    Write-Host "    Folder right-click     -> Claude Code"
    Write-Host "    Folder background right-click -> Claude Code"
    Write-Host ""
    Write-Host "Note: On Windows 11, the menu entry may appear under 'Show more options' (Shift+F10)."
}
```

- [ ] **Step 2: Verify PowerShell syntax**

Run:
```powershell
$errors = [System.Management.Automation.Language.Parser]::ParseFile(
    "$PSScriptRoot\install-claudecode-context-menu.ps1",
    [ref]$null,
    [ref]$null
)
if ($errors.Count -eq 0) { Write-Host "PASS: No syntax errors" } else { Write-Host "FAIL: $($errors.Count) errors" }
```

Expected: `PASS: No syntax errors`

- [ ] **Step 3: Test -WhatIf mode**

Run:
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1 -WhatIf
```

Expected: Output shows "WhatIf:" lines for all registry operations and file copy, but no actual writes.

- [ ] **Step 4: Commit**

```bash
git add install-claudecode-context-menu.ps1
git commit -m "feat: rewrite installer with params, pre-flight check, and version tracking"
```

---

### Task 3: Enhance uninstall-claudecode-context-menu.ps1

**Files:**
- Modify: `uninstall-claudecode-context-menu.ps1` (lines 1-20)

- [ ] **Step 1: Write the enhanced uninstaller**

```powershell
param(
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

# Confirmation
if (-not $Force) {
    $confirmation = Read-Host "Remove 'Claude Code' context menu entries? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "Cancelled."
        exit 0
    }
}

$appDir = Join-Path $env:LOCALAPPDATA 'ClaudeCodeContextMenu'
$registryPaths = @(
    'HKCU:\Software\Classes\Directory\shell\ClaudeCode'
    'HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode'
)

$removedCount = 0
foreach ($path in $registryPaths) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Recurse -Force
        Write-Host "Removed registry: $path"
        $removedCount++
    } else {
        Write-Host "Not found (skipped): $path"
    }
}

if (Test-Path -LiteralPath $appDir) {
    Remove-Item -LiteralPath $appDir -Recurse -Force
    Write-Host "Removed directory: $appDir"
} else {
    Write-Host "Not found (skipped): $appDir"
}

Write-Host "Uninstalled 'Claude Code' context menu ($removedCount registry entries removed)."
```

- [ ] **Step 2: Verify PowerShell syntax**

Run:
```powershell
$errors = [System.Management.Automation.Language.Parser]::ParseFile(
    "$PSScriptRoot\uninstall-claudecode-context-menu.ps1",
    [ref]$null,
    [ref]$null
)
if ($errors.Count -eq 0) { Write-Host "PASS: No syntax errors" } else { Write-Host "FAIL: $($errors.Count) errors" }
```

Expected: `PASS: No syntax errors`

- [ ] **Step 3: Commit**

```bash
git add uninstall-claudecode-context-menu.ps1
git commit -m "feat: add confirmation prompt and -Force param to uninstaller"
```

---

### Task 4: Update README.md and README.zh-CN.md

**Files:**
- Modify: `README.md`
- Modify: `README.zh-CN.md`

- [ ] **Step 1: Update README.md — replace Install and Uninstall sections**

Replace the **Install** section (lines 24-41) with:

```markdown
## Install

Open PowerShell in this project folder and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1
```

The installer copies `Open-ClaudeCode.ps1` to `%LOCALAPPDATA%\ClaudeCodeContextMenu\` and writes two current-user registry entries:

- `HKCU:\Software\Classes\Directory\shell\ClaudeCode`
- `HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode`

**Parameters:**

- `-Force` — skip prompts (e.g., when `claude` is not in PATH).
- `-WhatIf` — preview what would be installed without making changes.
```

Replace the **Uninstall** section (lines 56-64) with:

```markdown
## Uninstall

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1
```

This removes the `Claude Code` context menu entries and deletes the helper folder under `%LOCALAPPDATA%`.

**Parameters:**

- `-Force` — skip the confirmation prompt.
```

- [ ] **Step 2: Update README.zh-CN.md — replace Install and Uninstall sections**

Replace the **安装** section (lines 24-41) with:

```markdown
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
```

Replace the **卸载** section (lines 56-64) with:

```markdown
## 卸载

运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1
```

卸载脚本会删除 `Claude Code` 右键菜单项，并移除 `%LOCALAPPDATA%` 下的 helper 目录。

**参数：**

- `-Force` — 跳过确认提示。
```

- [ ] **Step 3: Commit**

```bash
git add README.md README.zh-CN.md
git commit -m "docs: update READMEs with new file structure and parameters"
```

---

### Task 5: Integration verification

- [ ] **Step 1: Run install with -WhatIf**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1 -WhatIf
```

Expected: Output lists all planned registry and file operations without modifying the system.

- [ ] **Step 2: Run install for real**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1 -Force
```

Expected: `Installed 'Claude Code' context menu (v2.0).` with helper path and summary.

- [ ] **Step 3: Verify registry entries exist**

```powershell
Get-Item -Path 'HKCU:\Software\Classes\Directory\shell\ClaudeCode'
Get-ItemProperty -Path 'HKCU:\Software\Classes\Directory\shell\ClaudeCode' -Name 'Version'
```

Expected: Both calls succeed; `Version` is `2.0`.

- [ ] **Step 4: Verify helper was copied**

```powershell
Test-Path "$env:LOCALAPPDATA\ClaudeCodeContextMenu\Open-ClaudeCode.ps1"
```

Expected: `True`

- [ ] **Step 5: Run uninstall with confirmation (answer N)**

Run interactively:
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1
```
Type `N` at the prompt.

Expected: `Cancelled.` — registry entries still exist.

- [ ] **Step 6: Run uninstall with -Force**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1 -Force
```

Expected: Registry entries and helper directory are removed with status messages.

- [ ] **Step 7: Verify cleanup**

```powershell
Test-Path 'HKCU:\Software\Classes\Directory\shell\ClaudeCode'
Test-Path "$env:LOCALAPPDATA\ClaudeCodeContextMenu"
```

Expected: Both return `False`.

- [ ] **Step 8: Run uninstall again (already clean)**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1 -Force
```

Expected: Shows "Not found (skipped)" for all items, reports 0 registry entries removed.

- [ ] **Step 9: Full functional test**

Re-install with `-Force`, then:
1. Open File Explorer, right-click a folder → click `Claude Code` → verify terminal opens in that directory and `claude` runs.
2. Open a folder, right-click empty space → click `Claude Code` → same verification.
3. Test with a path containing spaces: create `C:\test folder with spaces\`, right-click it → verify.
4. Test with a path containing Chinese characters: create `C:\测试目录\`, right-click it → verify.

- [ ] **Step 10: Final commit (if any README tweaks needed)**

```bash
git add -A
git commit -m "chore: final integration verification tweaks"
```

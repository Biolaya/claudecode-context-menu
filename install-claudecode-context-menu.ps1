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

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$menuKeyName = 'ClaudeCode'
$appName = 'Claude Code Context Menu'

function Get-LocalAppDataRoot {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')

    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        $localAppData = $env:LOCALAPPDATA
    }

    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        throw 'LOCALAPPDATA is not available. Cannot locate the install directory.'
    }

    return [System.IO.Path]::GetFullPath($localAppData)
}

$localAppData = Get-LocalAppDataRoot
$appDir = Join-Path $localAppData 'ClaudeCodeContextMenu'
$helperPath = Join-Path $appDir 'Open-ClaudeCode.ps1'
$markerPath = Join-Path $appDir '.installed-by-claude-code-context-menu'

$registryPaths = @(
    "HKCU:\Software\Classes\Directory\shell\$menuKeyName"
    "HKCU:\Software\Classes\Directory\Background\shell\$menuKeyName"
    "HKCU:\Software\Classes\Drive\shell\$menuKeyName"
)

Write-Host "$appName uninstaller"
Write-Host "Registry entries:"
foreach ($path in $registryPaths) {
    Write-Host "  $path"
}
Write-Host "Known installed files:"
Write-Host "  $helperPath"
Write-Host "  $markerPath"

if (-not $Force -and -not $WhatIfPreference) {
    $confirmation = Read-Host "Remove '$appName' from the current user? (y/N)"

    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host 'Cancelled.'
        exit 0
    }
}

$removedCount = 0

foreach ($path in $registryPaths) {
    if (Test-Path -LiteralPath $path) {
        if ($PSCmdlet.ShouldProcess($path, 'Remove context menu registry entry')) {
            Remove-Item -LiteralPath $path -Recurse -Force
            Write-Host "Removed registry: $path"
            $removedCount++
        }
    } else {
        Write-Host "Not found (skipped): $path"
    }
}

foreach ($filePath in @($helperPath, $markerPath)) {
    if (Test-Path -LiteralPath $filePath) {
        if ($PSCmdlet.ShouldProcess($filePath, 'Remove installed file')) {
            Remove-Item -LiteralPath $filePath -Force
            Write-Host "Removed file: $filePath"
        }
    } else {
        Write-Host "Not found (skipped): $filePath"
    }
}

if ($WhatIfPreference -and (Test-Path -LiteralPath $appDir)) {
    Write-Host "WhatIf: The install directory would be removed only if it is empty after known files are removed: $appDir"
} elseif (Test-Path -LiteralPath $appDir) {
    $remainingItems = @(Get-ChildItem -LiteralPath $appDir -Force)

    if ($remainingItems.Count -eq 0) {
        if ($PSCmdlet.ShouldProcess($appDir, 'Remove empty install directory')) {
            Remove-Item -LiteralPath $appDir -Force
            Write-Host "Removed empty directory: $appDir"
        }
    } else {
        Write-Warning "Left install directory in place because it contains unknown files: $appDir"
    }
} else {
    Write-Host "Not found (skipped): $appDir"
}

Write-Host "Uninstalled '$appName' ($removedCount registry entries removed)."

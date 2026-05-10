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

$ErrorActionPreference = 'Stop'

$appDir = Join-Path $env:LOCALAPPDATA 'ClaudeCodeContextMenu'
$registryPaths = @(
    'HKCU:\Software\Classes\Directory\shell\ClaudeCode'
    'HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode'
)

foreach ($path in $registryPaths) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Recurse -Force
    }
}

if (Test-Path -LiteralPath $appDir) {
    Remove-Item -LiteralPath $appDir -Recurse -Force
}

Write-Host "Uninstalled 'Claude Code' context menu entries."

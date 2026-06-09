[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$menuKeyName = 'ClaudeCode'
$menuVerb = 'Open Claude Code here'
$appName = 'Claude Code Context Menu'
$versionPath = Join-Path $PSScriptRoot 'VERSION'
$version = if (Test-Path -LiteralPath $versionPath) {
    (Get-Content -LiteralPath $versionPath -Raw).Trim()
} else {
    'dev'
}

function Get-LocalAppDataRoot {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')

    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        $localAppData = $env:LOCALAPPDATA
    }

    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        throw 'LOCALAPPDATA is not available. Cannot choose an install location.'
    }

    return [System.IO.Path]::GetFullPath($localAppData)
}

function Get-WindowsPowerShellPath {
    $candidate = Join-Path $PSHOME 'powershell.exe'

    if (Test-Path -LiteralPath $candidate) {
        return (Get-Item -LiteralPath $candidate).FullName
    }

    $candidate = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

    if (Test-Path -LiteralPath $candidate) {
        return (Get-Item -LiteralPath $candidate).FullName
    }

    throw 'Windows PowerShell was not found.'
}

function Quote-CommandLineArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value,

        [switch] $AlwaysQuote
    )

    if ($Value.Length -eq 0) {
        return '""'
    }

    if (-not $AlwaysQuote -and $Value -notmatch '[\s"]') {
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

function Resolve-ClaudeIconPath {
    param(
        [object] $ClaudeCommand,
        [string] $FallbackIcon
    )

    if ($ClaudeCommand -and $ClaudeCommand.Source) {
        $source = $ClaudeCommand.Source

        if ($source.EndsWith('.exe', [System.StringComparison]::OrdinalIgnoreCase)) {
            return $source
        }

        if ($source.EndsWith('.ps1', [System.StringComparison]::OrdinalIgnoreCase)) {
            $scriptDirectory = Split-Path -Parent $source
            $npmClaudeExe = Join-Path $scriptDirectory 'node_modules\@anthropic-ai\claude-code\bin\claude.exe'

            if (Test-Path -LiteralPath $npmClaudeExe) {
                return (Get-Item -LiteralPath $npmClaudeExe).FullName
            }
        }
    }

    return $FallbackIcon
}

$localAppData = Get-LocalAppDataRoot
$appDir = Join-Path $localAppData 'ClaudeCodeContextMenu'
$helperPath = Join-Path $appDir 'Open-ClaudeCode.ps1'
$markerPath = Join-Path $appDir '.installed-by-claude-code-context-menu'
$sourceHelper = Join-Path $PSScriptRoot 'Open-ClaudeCode.ps1'
$powerShellPath = Get-WindowsPowerShellPath

if (-not (Test-Path -LiteralPath $sourceHelper)) {
    throw "Open-ClaudeCode.ps1 not found next to this installer. Make sure both scripts are in the same directory."
}

$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue

if (-not $claudeCmd) {
    Write-Warning "claude was not found in your PATH. The menu can be installed, but it will not work until Claude Code is available as 'claude'."
}

$iconPath = Resolve-ClaudeIconPath -ClaudeCommand $claudeCmd -FallbackIcon $powerShellPath

$entries = @(
    @{
        Name = 'Folder right-click'
        Path = "HKCU:\Software\Classes\Directory\shell\$menuKeyName"
        Placeholder = '%1'
    }
    @{
        Name = 'Folder background right-click'
        Path = "HKCU:\Software\Classes\Directory\Background\shell\$menuKeyName"
        Placeholder = '%V'
    }
    @{
        Name = 'Drive right-click'
        Path = "HKCU:\Software\Classes\Drive\shell\$menuKeyName"
        Placeholder = '%1'
    }
)

foreach ($entry in $entries) {
    $entry.CommandPath = Join-Path $entry.Path 'command'
    $entry.Command = @(
        (Quote-CommandLineArgument -Value $powerShellPath -AlwaysQuote)
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        (Quote-CommandLineArgument -Value $helperPath -AlwaysQuote)
        (Quote-CommandLineArgument -Value $entry.Placeholder -AlwaysQuote)
    ) -join ' '
}

Write-Host "$appName installer v$version"
Write-Host "Helper source: $sourceHelper"
Write-Host "Helper target: $helperPath"
Write-Host "Menu text: $menuVerb"
Write-Host "Icon: $iconPath"
Write-Host "Registry entries:"
foreach ($entry in $entries) {
    Write-Host "  $($entry.Name): $($entry.Path)"
    Write-Host "    $($entry.Command)"
}

if (-not $Force -and -not $WhatIfPreference) {
    $continue = Read-Host 'Install these current-user context menu entries? (y/N)'

    if ($continue -ne 'y' -and $continue -ne 'Y') {
        Write-Host 'Installation cancelled.'
        exit 0
    }
}

if ($PSCmdlet.ShouldProcess($appDir, 'Create application directory')) {
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
}

if ($PSCmdlet.ShouldProcess($helperPath, 'Copy launcher helper')) {
    Copy-Item -LiteralPath $sourceHelper -Destination $helperPath -Force
}

if ($PSCmdlet.ShouldProcess($markerPath, 'Write installer marker')) {
    Set-Content -LiteralPath $markerPath -Value @(
        "Name=$appName"
        "Version=$version"
        "InstalledAt=$((Get-Date).ToString('s'))"
        "Helper=$helperPath"
    ) -Encoding UTF8
}

$installedEntries = 0

foreach ($entry in $entries) {
    if ($PSCmdlet.ShouldProcess($entry.Path, 'Create or update context menu registry entry')) {
        New-Item -Path $entry.Path -Force | Out-Null
        Set-Item -Path $entry.Path -Value $menuVerb
        New-ItemProperty -Path $entry.Path -Name 'MUIVerb' -Value $menuVerb -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $entry.Path -Name 'Icon' -Value $iconPath -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $entry.Path -Name 'Version' -Value $version -PropertyType String -Force | Out-Null

        New-Item -Path $entry.CommandPath -Force | Out-Null
        Set-Item -Path $entry.CommandPath -Value $entry.Command

        $installedEntries++
    }
}

if (-not $WhatIfPreference) {
    Write-Host ''
    Write-Host "Installed '$menuVerb' context menu (v$version)."
    Write-Host "Helper: $helperPath"
    Write-Host "Registry entries installed: $installedEntries"
    Write-Host "Run .\uninstall-claudecode-context-menu.ps1 to remove it."
    Write-Host ''
    Write-Host "Note: On Windows 11, classic registry menu entries may appear under 'Show more options' (Shift+F10)."
}

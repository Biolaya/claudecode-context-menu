$ErrorActionPreference = 'Stop'

$menuName = 'Claude Code'
$appDir = Join-Path $env:LOCALAPPDATA 'ClaudeCodeContextMenu'
$helperPath = Join-Path $appDir 'Open-ClaudeCode.ps1'

New-Item -ItemType Directory -Path $appDir -Force | Out-Null

$helperScript = @'
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $TargetDirectory
)

$ErrorActionPreference = 'Stop'

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
'@

Set-Content -LiteralPath $helperPath -Value $helperScript -Encoding UTF8

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

    New-Item -Path $shellPath -Force | Out-Null
    Set-Item -Path $shellPath -Value $menuName
    New-ItemProperty -Path $shellPath -Name 'Icon' -Value 'powershell.exe' -PropertyType String -Force | Out-Null

    New-Item -Path $commandPath -Force | Out-Null
    Set-Item -Path $commandPath -Value $command
}

Write-Host "Installed '$menuName' context menu entries."
Write-Host "Helper script: $helperPath"

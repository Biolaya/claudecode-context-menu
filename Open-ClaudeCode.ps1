[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $TargetDirectory
)

$ErrorActionPreference = 'Stop'

# PowerShell 5.1's Start-Process -ArgumentList with an array does not handle
# double-quote/backslash escaping consistently, so build command lines using
# Windows command-line parsing rules.
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

function Join-CommandLineArguments {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    return ($Arguments | ForEach-Object { Quote-CommandLineArgument -Value $_ }) -join ' '
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

function Start-ClaudeInPowerShell {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Directory,

        [Parameter(Mandatory = $true)]
        [string] $PowerShellPath
    )

    $arguments = Join-CommandLineArguments -Arguments @(
        '-NoExit'
        '-NoProfile'
        '-Command'
        'claude'
    )

    Start-Process -FilePath $PowerShellPath -WorkingDirectory $Directory -ArgumentList $arguments
}

function Show-LaunchError {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    try {
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            $Message,
            'Claude Code',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        return
    } catch {
        Write-Error $Message
    }

    try {
        $powerShellPath = Get-WindowsPowerShellPath
        $escapedMessage = $Message.Replace("'", "''")
        $arguments = Join-CommandLineArguments -Arguments @(
            '-NoExit'
            '-NoProfile'
            '-Command'
            "Write-Error '$escapedMessage'"
        )

        Start-Process -FilePath $powerShellPath -ArgumentList $arguments
    } catch {
        Write-Error $Message
    }
}

try {
    if (-not $TargetDirectory -or $TargetDirectory -eq '%1' -or $TargetDirectory -eq '%V') {
        throw 'This script expects a folder path from the Claude Code context menu. Launch it by right-clicking a folder, folder background, or drive in File Explorer.'
    }

    $target = Get-Item -LiteralPath $TargetDirectory -ErrorAction Stop

    if (-not $target.PSIsContainer -or $target.PSProvider.Name -ne 'FileSystem' -or -not ($target -is [System.IO.DirectoryInfo])) {
        throw "Target path is not a filesystem directory: $TargetDirectory"
    }

    $directory = $target.FullName
    $powerShellPath = Get-WindowsPowerShellPath
    $wt = Get-Command wt.exe -ErrorAction SilentlyContinue

    if ($wt) {
        $wtArguments = Join-CommandLineArguments -Arguments @(
            '-d'
            $directory
            $powerShellPath
            '-NoExit'
            '-NoProfile'
            '-Command'
            'claude'
        )

        try {
            $process = Start-Process -FilePath $wt.Source -ArgumentList $wtArguments -PassThru
            Start-Sleep -Milliseconds 800

            if (-not $process.HasExited -or $process.ExitCode -eq 0) {
                exit 0
            }
        } catch {
            # Fall back to Windows PowerShell below.
        }
    }

    Start-ClaudeInPowerShell -Directory $directory -PowerShellPath $powerShellPath
} catch {
    Show-LaunchError -Message $_.Exception.Message
    exit 1
}

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

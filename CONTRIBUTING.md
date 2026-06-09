# Contributing

Thanks for improving Claude Code Windows Context Menu.

## Development Guidelines

- Keep the project lightweight and current-user scoped.
- Do not require administrator permission for normal install or uninstall flows.
- Keep English and Chinese README updates in sync.
- Prefer explicit, auditable PowerShell over hidden side effects.
- Use `-WhatIf` for any script path that writes registry entries or files.

## Local Checks

Run these before opening a pull request:

```powershell
$files = Get-ChildItem -Recurse -Filter *.ps1
foreach ($file in $files) {
    $null = [scriptblock]::Create((Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8))
}

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-claudecode-context-menu.ps1 -Force -WhatIf
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall-claudecode-context-menu.ps1 -Force -WhatIf
```

## Manual Verification

When changing install or launch behavior, test:

- Folder right-click.
- Folder background right-click.
- Drive root right-click.
- Paths with spaces.
- Paths with Chinese characters.
- Windows Terminal present.
- Windows Terminal unavailable or disabled.
- Missing `claude` command.
- Uninstall and reinstall.

## Documentation

If behavior changes, update both:

- `README.md`
- `README.zh-CN.md`

Add a `CHANGELOG.md` entry for user-visible changes.

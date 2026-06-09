# Changelog

All notable changes to this project are documented here.

## 2.1.0 - 2026-06-09

- Added standard PowerShell `-WhatIf` and `-Confirm` support to install and uninstall scripts.
- Added safer uninstall behavior that removes known files and deletes the install directory only when empty.
- Added drive root context-menu support.
- Added explicit `MUIVerb`, version metadata, and a clearer menu label: `Open Claude Code here`.
- Switched registry commands to an absolute Windows PowerShell path.
- Improved command-line quoting for registry commands.
- Added launcher validation for filesystem directories.
- Added Windows Terminal immediate-failure fallback.
- Added a helper install marker file.
- Added `.gitignore`, `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md`, and CI.
- Expanded English and Chinese README documentation.

## 2.0.0 - 2026-05-10

- Split the launcher into `Open-ClaudeCode.ps1`.
- Added `-Force` and preview support to the installer.
- Added uninstall confirmation.
- Improved Windows Terminal launch behavior.

## 1.0.0 - 2026-05-10

- Added current-user File Explorer context menu entries for folders and folder backgrounds.
- Added Windows Terminal preference with Windows PowerShell fallback.
- Added English and Chinese README files.

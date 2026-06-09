# Security Policy

## Scope

This project installs current-user Windows Explorer context menu entries and a helper script under `%LOCALAPPDATA%`.

Security-sensitive areas include:

- Registry command construction.
- PowerShell execution policy usage.
- PATH-based `claude` resolution.
- Install and uninstall file deletion behavior.

## Reporting a Vulnerability

Please open a private report through GitHub Security Advisories if available. If that is not available, open a GitHub issue with a minimal description and avoid posting exploit details publicly until the issue is understood.

## Design Expectations

- Normal install and uninstall should not require administrator permission.
- Scripts should avoid machine-wide registry writes.
- Uninstall should remove only known project-owned files.
- The launcher should validate paths before starting a terminal.

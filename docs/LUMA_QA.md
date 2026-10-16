# Luma v0.8.0 — Windows build and QA

Date: 2026-10-16 (device local time, UTC+08:00)
Repository: buyuuz/Luma, branch `branding/luma`
System: Windows 10 Enterprise LTSC 2021 x64, build 19044
Compiler: MSVC 19.44 (Visual Studio 2022 Build Tools)
Qt: 6.12.0 msvc2022_64

## Verified

- Release compilation: PASS (`D:\Luma\build\release\Luma.exe`)
- CTest (full suite, release.ps1 packaging run): **13/13 PASS**; exit code 0, 95.55 seconds
- Suites: tst_core, tst_service, tst_clipboard, tst_favorites, tst_color,
  tst_dragout, tst_siteicon, tst_backup, tst_ocr, tst_tools,
  tst_semantic, tst_mcp, tst_plugin
- Installer compilation: PASS (Inno Setup)
- Portable ZIP packaging: PASS
- SHA256SUMS checked against both generated files: PASS
- Packaged executable `--version`: `Luma 0.8.0` (exit 0)
- Portable smoke check with isolated `--profile`, `--background`, `--quit`:
  process starts and quits normally (PASS)
- No Luma install/service left registered after earlier isolated install/uninstall
  exercise. **No installation was performed for this final testing round.**

## Changes verified during QA

- Update tests for Luma application self-identification and backup naming.
- Fix default MCP visibility token fallback for elevated built-in Administrator
  accounts without a UAC-linked token. Instead of checking files using full
  administrator rights, derive a restricted deny-only Administrators token.
  Fail closed if token restriction fails.
- Test plugins under either a valid Explorer token or the secure restricted
  fallback. Verify that the runner and plugins are not elevated and that job,
  process, and clipboard permissions remain enforced.
- Account for the operating system returning ERROR_INVALID_HANDLE for clipboard
  reads in a restricted-token remote desktop session, while still asserting
  that the plugin's job does not block an explicitly allowed clipboard read.

## Local release artifacts

- `D:\Luma\dist\Luma-0.8.0-x64-setup.exe`
  SHA256: `42d79c39a47172581778cb654b8eade7e7d6fac39ce25365b9698c6b7b255b6a`
- `D:\Luma\dist\Luma-0.8.0-x64-portable.zip`
  SHA256: `75990c18cf0d684474baf66b56175d0f992117933ba998957c109ae0bdce1721`
- `D:\Luma\dist\SHA256SUMS.txt`

## Limits and environment details

- All included automated tests pass on this particular Windows system; this
  does not guarantee every interactive UI workflow, hardware configuration,
  or third-party plugin.
- Qt's optional private `Qt6TaskTree` and Vulkan-header detection warnings
  did not block compilation, tests, or packaging.
- The VS Build Tools installer advised reboot (exit 3010), but no reboot was
  performed, and compilation/tests succeeded without one.
- Generated packages are unsigned. Windows SmartScreen may prompt on launch.
- The online GitHub branch was **not** updated by this QA run; the commit is
  local until authenticated Git push succeeds.
- Do not install until the user explicitly chooses to install after review.

# Luma V6 — Qt per-pixel alpha rounded launcher

## Why V5 still showed damaged corners

October 16, 2026: the user showed edge artifacts on a 980x205 Windows 10 LTSC search window even after the earlier QML outline fixes. The launcher was simultaneously:
- shaped by Win32 `SetWindowRgn(CreateRoundRectRgn(...))` (hard, 1-bit mask);
- tinted by undocumented Win10 `SetWindowCompositionAttribute` acrylic (rectangular compositor surface);
- painted with Qt Quick antialiased, independently rounded background.

This leaves seams, jagged mixed-opacity pixels and multiple outer edges. A QML-only border fix cannot correct the native mask.

## V6 approach

- Launcher only: call `styleFramelessWindow(..., perPixelAlpha=true)` from `App::applyTheme`.
- On Windows 10, do **not** install a `SetWindowRgn` mask for the launcher. Do **not** set the private Acrylic composition policy or DWM extra frame on it. **Do not call `SetWindowRgn(nullptr)`** either: an experiment with that Win32 call caused the window to stay invisible after opening on this device; simply skip region creation.
- Use the existing launcher `QQuickWindow` `Qt::transparent` background and alpha-buffer request. The QML 22px root rectangle handles antialiasing and real pixel transparency at the rounded silhouette.
- Keep the glass gradient itself opaque (alpha=1), so desktop text does not show through the list body. The only transparency necessary here is outside the rounded silhouette.
- Other Windows windows (settings, clipboard, dialog bar) keep their original `styleFramelessWindow` path; no search/index/service logic changes.
- Explicit tradeoff: this launcher visual mode does not use Windows 10 native Acrylic blur. Its neutral graphite appearance is preserved; revisit blur only if a pixel-alpha-compatible solution is verified without breaking corners.

## Actual device verification

- Windows 10 LTSC, Qt 6.12 / MSVC: V6 executable compiled successfully.
- Real 980x300 resized launcher query: `9201E.png` returned 2 results.
- Pure magenta test window filled the entire desktop behind Luma. Direct `System.Drawing.CopyFromScreen` pixel sampling of the foreground window:
  - top-left 0,0: `255,0,255`
  - top-right 979,0: `255,0,255`
  - bottom-left 0,299: `255,0,255`
  - bottom-right 979,299: `255,0,255`
  - center: `64,65,67` (opaque dark graphite)
- This distinguishes truly transparent corners from opaque or hard-masked corner pixels. Screenshots: `D:\Luma-Toolchain\luma-v6-magenta-proof.png` and `luma-v6-alpha.png`.
- Full CTest run: **13/13 test groups passed**, 105.12 seconds; exit code 0.
- Packaged final V6 preview ZIP: `D:\Luma\dist\Luma-Raycast-v6-alpha-preview.zip` (50,420,979 bytes), with `PREVIEW_SCREENSHOT.png` and magenta `CORNER_ALPHA_PROOF.png`.
- Final preview SHA256: `B91E72B56BF9F19C57185282332676224B5FB589171D9670A008A7FBBDD230F7`.
- ZIP extracted and verified: `START_PREVIEW.cmd` launched Luma using isolated profile, then `--quit` exited normally.
- The stable Luma LocalSystem service was not stopped or reinstalled. Windows 11 frame behavior is kept on its original path but has not been verified on an actual Windows 11 machine.

## Version isolation

V6 branch `ui/raycast-alpha-corners-v6`; stable `main` and v0.8.0 Release are not changed, and the installed Luma service remains untouched.

# Changelog

## [2.0.0] - 2026-08-31

**Wallpaper Setting & Preview Utility** — a type-safe, result-based rewrite.

### Breaking changes

- Replaced string targets (`"home"`, `"lock"`, `"both"`) with the typed `WallpaperTarget` enum.
- All wallpaper operations now return `Future<WallpaperResult>` instead of `Future<bool>`.
- Removed `WallpaperPlugin.getPlatformVersion()`.
- Android manifest setup is now fully bundled (`SET_WALLPAPER` permission, `FileProvider`, `file_paths.xml`) — apps no longer add these manually.

### New features

- New image sources: `setWallpaperFromFile`, `setWallpaperFromUrl`, `setWallpaperFromBytes`.
- `RepaintBoundary` support preserved: `setWallpaperFromRepaintBoundary(GlobalKey, WallpaperTarget)`.
- Structured `WallpaperResult` with a typed `WallpaperError` (supported / invalid image / permission / platform / network / file / unknown).
- `getCapabilities()` reports genuine platform support (home / lock / both / captured widget / direct image sources).
- `getScreenInfo()` exposes reliable width / height / pixel density / orientation.
- `WallpaperFit` (`cover` / `contain` / `fill`) optional scaling on Android — avoids distortion and excessive memory use.
- `useAsImageFromRepaintBoundary()` share flow preserved on Android and iOS.

### Android

- Bounded bitmap decoding (~2× screen resolution) to avoid `OutOfMemoryError` on very large images.
- Home / Lock / Both target handling via `FlagLock` / `FlagsSystem`; lock and both require Android 7.0+.
- Explicit bitmap cleanup and temp-file cleanup in the Dart pipeline.

### iOS

- Wallpaper setting reports an explicit `unsupported` result — no fake behavior, no crashes.
- `getCapabilities()` honestly reports no wallpaper-setting support.
- `getScreenInfo()` and the Use As... share flow remain available.

### Tests

- Dart: model tests (`WallpaperTarget`, `WallpaperError`, `WallpaperResult`, `WallpaperCapabilities`, `WallpaperFit`), platform routing, method-channel mapping, URL/bytes/file handling, PlatformException error mapping, and temp-file cleanup.
- Android (JVM): capabilities, error paths (missing file, undecodable image), and `cover`/`contain` scaling math.
- iOS (XCTest): unsupported result, honest capabilities, screen info, invalid share input.
- Example: widget tests for the grid and preview screen; integration test updated to `WallpaperTarget`.

## [1.0.1] - 2026-05-21

### Bug Fixes:

- Fixed MethodChannel name mismatch (`wallpaper_plugin` → `com.iamporag/wallpaper`)
- Fixed `byteData` null safety — removed force unwrap (`!`)
- Fixed bitmap null check before setting wallpaper on Android
- Fixed `SET_WALLPAPER` permission missing in plugin `AndroidManifest.xml`
- Fixed `FileProvider` not configured in example app `AndroidManifest.xml`

### Improvements:

- `WallpaperPlugin` no longer calls `MethodChannel` directly
- All calls now route through `WallpaperPluginPlatform.instance`
- Image capture logic moved to `MethodChannelWallpaperPlugin`
- Added temp file cleanup after wallpaper is set
- `setWallpaper()` and `useAsImage()` are now declared in platform interface
- Added confirmation dialog before setting wallpaper (Home, Lock, Both)
- Removed `photo_view` from plugin dependencies — moved to example app only

## [1.0.0] - 2025-08-14

- **iOS support** for setting wallpapers

🎉 Initial release of `wallpaper_setter`.

### Features:

- Set device wallpaper from **URL** or **asset image**.
- Uses the **default Android system wallpaper picker UI**.
- Supports setting wallpaper to:

### Android

- Home screen
- Lock screen
- Both screens

### iOS

- Use As.. (Just click and magic)
- Home/Lock screen cannot be set programmatically (Apple restriction).
- Users are guided to manually set wallpaper via Photos app.
- Added support for **NSPhotoLibraryAddUsageDescription** and **NSPhotoLibraryUsageDescription** in `Info.plist`.

- Provides method to **share or use image** via `useAsImageFromRepaintBoundary`.
- Example project with preview and full-screen photo view support.

### Android Setup:

- Requires `file_paths.xml` configuration in `android/app/src/main/res/xml`.
- Requires permissions for setting wallpaper and reading storage/media.
- Includes `FileProvider` setup via manifest.

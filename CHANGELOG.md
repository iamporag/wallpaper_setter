# Changelog

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

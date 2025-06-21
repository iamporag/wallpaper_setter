# [0.0.1] - 2025-06-21
# [0.0.2] - 2025-06-21
# [0.0.3] - 2025-06-21

- Fixed Package Path and Add Demo.gif

🎉 Initial release of `wallpaper_setter`.

### Features:
- Set device wallpaper from **URL** or **asset image**.
- Uses the **default Android system wallpaper picker UI**.
- Supports setting wallpaper to:
  - Home screen
  - Lock screen
  - Both screens
- Provides method to **share or use image** via `useAsImageFromRepaintBoundary`.
- Example project with preview and full-screen photo view support.

### Android Setup:
- Requires `file_paths.xml` configuration in `android/app/src/main/res/xml`.
- Requires permissions for setting wallpaper and reading storage/media.
- Includes `FileProvider` setup via manifest.

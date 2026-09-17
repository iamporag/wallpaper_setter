# wallpaper_setter

A lightweight Flutter plugin for **setting device wallpapers** and **using images as wallpapers / shares**.

`wallpaper_setter` turns your image sources — **file**, **URL**, **raw bytes**, or a captured **RepaintBoundary** — into a device wallpaper with a simple, type-safe API.

- ✅ **Android** — set Home screen, Lock screen, or Both
- ⚠️ **iOS** — wallpapers cannot be set programmatically (Apple restriction); the plugin returns a clear `unsupported` result and provides a **Use As...** share flow instead
- 🧱 No magic strings, no boilerplate, result-based error handling

---

## Features

| API | Purpose |
| --- | --- |
| `setWallpaperFromFile` | Set wallpaper from a local `File` |
| `setWallpaperFromUrl` | Download and set wallpaper from a network URL |
| `setWallpaperFromBytes` | Set wallpaper from raw JPEG/PNG `Uint8List` |
| `setWallpaperFromRepaintBoundary` | Capture any widget and set it as wallpaper |
| `useAsImageFromRepaintBoundary` | Share / export a widget via the system share sheet |
| `getCapabilities` | Query what the current platform genuinely supports |
| `getScreenInfo` | Read reliable screen width/height/density/orientation |
| `WallpaperTarget` | Type-safe target: `home`, `lock`, or `both` |
| `WallpaperFit` | Optional `cover` / `contain` / `fill` scaling |
| `WallpaperResult` | Structured success/failure outcomes |

---

## Installation

```yaml
dependencies:
  wallpaper_setter: ^2.0.0
```

Then:

```bash
flutter pub get
```

### Android

No manual setup is required. The plugin bundles:

- The `SET_WALLPAPER` permission in its own manifest
- Its own `FileProvider` (`${applicationId}.wallpaper_setter.fileprovider`)
- A safe `file_paths.xml`

> You no longer need to add permissions, a provider, or `file_paths.xml` to your app's manifest (required in v1.x).

### iOS

No setup required. Wallpaper-setting APIs are not available — the plugin detects this and returns an `unsupported` result. The **Use As...** share flow works out of the box.

---

## Quick Start

```dart
import 'package:wallpaper_setter/wallpaper_setter.dart';

// Check what this platform supports before showing buttons.
final capabilities = await WallpaperPlugin.getCapabilities();

if (capabilities.supportsHome) {
  // ...
}
```

### Set wallpaper from a URL

```dart
final result = await WallpaperPlugin.setWallpaperFromUrl(
  'https://example.com/wallpaper.jpg',
  target: WallpaperTarget.home,
);

if (result.isSuccess) {
  // Wallpaper applied.
} else {
  // result.error is a WallpaperError, result.message is human readable.
  print('Failed: ${result.error} - ${result.message}');
}
```

### Set wallpaper from a file

```dart
import 'dart:io';

final result = await WallpaperPlugin.setWallpaperFromFile(
  File('/path/to/image.png'),
  target: WallpaperTarget.lock,
);
```

### Set wallpaper from bytes

```dart
final Uint8List bytes; // e.g. downloaded, decoded, or generated JPEG/PNG data

final result = await WallpaperPlugin.setWallpaperFromBytes(
  bytes,
  target: WallpaperTarget.both,
);
```

### Set wallpaper from a RepaintBoundary

Wrap any widget in a `RepaintBoundary` and capture it:

```dart
final GlobalKey previewKey = GlobalKey();

// In your widget tree:
RepaintBoundary(
  key: previewKey,
  child: /* your preview widget */,
);

// Apply it:
final result = await WallpaperPlugin.setWallpaperFromRepaintBoundary(
  previewKey,
  WallpaperTarget.home,
  pixelRatio: 2.5, // optional capture resolution
);
```

### Set both screens

```dart
final result = await WallpaperPlugin.setWallpaperFromBytes(
  bytes,
  target: WallpaperTarget.both,
);
```

### Optional image fitting

Avoid distortion by scaling before the wallpaper is applied:

```dart
final result = await WallpaperPlugin.setWallpaperFromFile(
  file,
  target: WallpaperTarget.both,
  fit: WallpaperFit.cover, // cover (default) | contain | fill
);
```

- `WallpaperFit.cover` — fills the screen, center-crops overflow *(recommended for wallpapers)*
- `WallpaperFit.contain` — fits entirely inside the screen with black letterbox bars
- `WallpaperFit.fill` — stretches to exactly fill the screen (may distort)

When `fit` is omitted the image is passed to the platform unscaled.

### Share / Use As (iOS and Android)

```dart
final result = await WallpaperPlugin.useAsImageFromRepaintBoundary(previewKey);
```

Opens the system share sheet so the user can save the image to Photos (then set it manually). This is the primary iOS flow.

---

## Error Handling

Every operation returns a `WallpaperResult` instead of throwing:

```dart
class WallpaperResult {
  final bool isSuccess;
  final WallpaperError? error;
  final String? message;
}
```

```dart
final result = await WallpaperPlugin.setWallpaperFromUrl(url, target: WallpaperTarget.home);
switch (result.error) {
  case WallpaperError.unsupported:
    // Platform cannot do this (e.g. iOS).
  case WallpaperError.invalidImage:
    // Bytes/file could not be decoded.
  case WallpaperError.permissionDenied:
  case WallpaperError.networkError:
  case WallpaperError.fileError:
  case WallpaperError.platformError:
  case WallpaperError.unknown:
    // ...
  case null:
    // No error.
}
```

Expected failures (missing files, bad URLs, unsupported platforms) return a structured failure — they never throw or crash.

---

## Capabilities

```dart
final capabilities = await WallpaperPlugin.getCapabilities();
```

| Field | Meaning |
| --- | --- |
| `supportsHome` | Can set the home screen wallpaper |
| `supportsLock` | Can set the lock screen wallpaper |
| `supportsBoth` | Can set both together |
| `supportsCapturedWidget` | Can set a wallpaper from a `RepaintBoundary` |
| `supportsDirectImageSources` | Can set a wallpaper from file/URL/bytes |
| `supportsWallpaperSetting` | Any of the above (convenience) |

Capabilities are only ever reported as `true` when the platform genuinely provides the behavior.

---

## Screen Information

```dart
final info = await WallpaperPlugin.getScreenInfo();
print('${info.width}x${info.height} @ ${info.pixelDensity} ${info.orientation}');
```

`width`, `height`, `pixelDensity` and `orientation` are `null` when a platform cannot provide them reliably.

---

## Supported Platforms

| Feature | Android | iOS |
| --- | --- | --- |
| Home wallpaper | ✅ | ❌ (unsupported) |
| Lock wallpaper | ✅ (Android 7.0+) | ❌ (unsupported) |
| Both | ✅ (Android 7.0+) | ❌ (unsupported) |
| RepaintBoundary source | ✅ | ❌ (unsupported) |
| File / URL / bytes source | ✅ | ❌ (unsupported) |
| `WallpaperFit` scaling | ✅ | n/a |
| Use As... / share | ✅ | ✅ |
| `getCapabilities` | ✅ | ✅ |
| `getScreenInfo` | ✅ | ✅ |

### Android limitations

- Lock screen and "Both" targets require **Android 7.0 (API 24)** or newer. On older devices the plugin reports `WallpaperError.unsupported` for those targets.
- Images are decoded with a size bound (~2× screen resolution) to keep memory usage predictable for very large images.
- Widget capture is limited to the widget's on-screen size (`RepaintBoundary.toImage`).

### iOS limitations

- iOS does **not** allow third-party apps to set wallpapers programmatically. `setWallpaperFromFile/Url/Bytes/RepaintBoundary` return `WallpaperError.unsupported` and never pretend to succeed.
- Use `useAsImageFromRepaintBoundary` to open the share sheet so the user can save and set the image manually.
- The package never crashes on iOS — unsupported operations are safe to call.

---

## Migration Guide 1.0.x → 2.0.0

v2.0.0 is an intentional, documented breaking release. Most changes are mechanical.

### 1. Targets use an enum instead of strings

```diff
- final bool ok = await WallpaperPlugin.setWallpaperFromRepaintBoundary(
-   previewKey, "home");
+ final WallpaperResult result =
+     await WallpaperPlugin.setWallpaperFromRepaintBoundary(
+       previewKey,
+       WallpaperTarget.home,
+     );
```

`"home"`, `"lock"`, `"both"` became `WallpaperTarget.home`, `WallpaperTarget.lock`, `WallpaperTarget.both`.

### 2. Results are structured, not `bool`

```diff
- final bool ok = await WallpaperPlugin.setWallpaperFromRepaintBoundary(...);
- if (ok) { ... }
+ final WallpaperResult result = await WallpaperPlugin.setWallpaperFromRepaintBoundary(...);
+ if (result.isSuccess) { ... } else { print(result.error?.name); }
```

All operations now return `Future<WallpaperResult>` instead of `Future<bool>`.

### 3. New image-source methods

```dart
WallpaperPlugin.setWallpaperFromFile(file, target: ...);
WallpaperPlugin.setWallpaperFromUrl(url, target: ...);
WallpaperPlugin.setWallpaperFromBytes(bytes, target: ...);
```

### 4. Removed API

- `WallpaperPlugin.getPlatformVersion()` — removed (unrelated to the plugin's purpose). Use `getCapabilities()` / `getScreenInfo()` instead.

### 5. Capability-aware UI

```diff
+ final caps = await WallpaperPlugin.getCapabilities();
+ if (caps.supportsLock) { /* show lock-button */ }
```

### 6. Fun fact — the call pattern is the same

Only the return type and target type changed; the method name and arguments layout are otherwise unchanged.

### Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

## Example App

Check the `example/` directory for a complete app demonstrating:

- Image grid (network + bundled demo file)
- Preview with zoom / pan
- Set as Home / Lock / Both
- Set from URL and File flows
- Loading and error states
- Platform-aware UI via `getCapabilities()`

---

## License

MIT — see [LICENSE](LICENSE).
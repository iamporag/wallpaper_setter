import 'package:flutter/foundation.dart';

/// The target screen on which a wallpaper should be set.
///
/// Replaces the magic strings (`"home"`, `"lock"`, `"both"`) used in v1.x
/// with a type-safe enum.
enum WallpaperTarget {
  /// Set the wallpaper on the home screen only.
  home,

  /// Set the wallpaper on the lock screen only.
  lock,

  /// Set the wallpaper on both the home and lock screens.
  both;

  /// Maps this enum to the string value understood by the native platform.
  ///
  /// Kept internal so that platform details never leak into the public API.
  String get nativeValue {
    switch (this) {
      case WallpaperTarget.home:
        return 'home';
      case WallpaperTarget.lock:
        return 'lock';
      case WallpaperTarget.both:
        return 'both';
    }
  }

  /// Resolves a native string value back into a [WallpaperTarget].
  ///
  /// Unknown values fall back to [WallpaperTarget.home].
  static WallpaperTarget fromNativeValue(String? value) {
    switch (value) {
      case 'lock':
        return WallpaperTarget.lock;
      case 'both':
        return WallpaperTarget.both;
      default:
        return WallpaperTarget.home;
    }
  }
}

/// Helpers for mapping [WallpaperError] values to/from native strings.
extension WallpaperErrorExtension on WallpaperError {
  /// The string value understood by the native platform.
  String get nativeValue {
    switch (this) {
      case WallpaperError.unsupported:
        return 'unsupported';
      case WallpaperError.invalidImage:
        return 'invalidImage';
      case WallpaperError.permissionDenied:
        return 'permissionDenied';
      case WallpaperError.platformError:
        return 'platformError';
      case WallpaperError.networkError:
        return 'networkError';
      case WallpaperError.fileError:
        return 'fileError';
      case WallpaperError.unknown:
        return 'unknown';
    }
  }

  /// Resolves a native string value back into a [WallpaperError].
  static WallpaperError? fromNativeValue(Object? value) {
    switch (value as String?) {
      case 'unsupported':
        return WallpaperError.unsupported;
      case 'invalidImage':
        return WallpaperError.invalidImage;
      case 'permissionDenied':
        return WallpaperError.permissionDenied;
      case 'platformError':
        return WallpaperError.platformError;
      case 'networkError':
        return WallpaperError.networkError;
      case 'fileError':
        return WallpaperError.fileError;
      case 'unknown':
        return WallpaperError.unknown;
      default:
        return null;
    }
  }
}

/// Known reasons a wallpaper operation may fail.
enum WallpaperError {
  /// The current platform does not support the requested operation.
  unsupported,

  /// The provided image could not be read or decoded.
  invalidImage,

  /// The operation was blocked by a missing permission.
  permissionDenied,

  /// An unexpected error occurred on the native platform.
  platformError,

  /// A network image could not be downloaded.
  networkError,

  /// A local file could not be read.
  fileError,

  /// An unexpected or unclassified error occurred.
  unknown,
}

/// The outcome of a wallpaper operation.
class WallpaperResult {
  const WallpaperResult._({required this.isSuccess, this.error, this.message});

  /// A successful result with an optional human readable [message].
  const WallpaperResult.success({String? message})
    : this._(isSuccess: true, error: null, message: message);

  /// A failed result describing the [error] that occurred.
  const WallpaperResult.failure(WallpaperError error, {String? message})
    : this._(isSuccess: false, error: error, message: message);

  /// Whether the operation completed successfully.
  final bool isSuccess;

  /// The error that occurred, or `null` when [isSuccess] is `true`.
  final WallpaperError? error;

  /// An optional human readable description of the outcome.
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WallpaperResult &&
          other.isSuccess == isSuccess &&
          other.error == error &&
          other.message == message;

  @override
  int get hashCode => Object.hash(isSuccess, error, message);

  @override
  String toString() =>
      'WallpaperResult(isSuccess: $isSuccess, error: $error, message: $message)';
}

/// Describes which wallpaper targets, if any, a platform supports.
///
/// Returned by [WallpaperPlugin.getCapabilities]. A capability is only
/// reported as `true` when the underlying platform genuinely provides it.
@immutable
class WallpaperCapabilities {
  const WallpaperCapabilities({
    required this.supportsHome,
    required this.supportsLock,
    required this.supportsBoth,
    required this.supportsCapturedWidget,
    required this.supportsDirectImageSources,
  });

  /// A constant describing a platform with no wallpaper-setting support
  /// (for example iOS, which cannot set wallpapers programmatically).
  static const WallpaperCapabilities none = WallpaperCapabilities(
    supportsHome: false,
    supportsLock: false,
    supportsBoth: false,
    supportsCapturedWidget: false,
    supportsDirectImageSources: false,
  );

  /// Whether the platform can set the home screen wallpaper.
  final bool supportsHome;

  /// Whether the platform can set the lock screen wallpaper.
  final bool supportsLock;

  /// Whether the platform can set home and lock together.
  final bool supportsBoth;

  /// Whether a widget captured from a [RepaintBoundary] can be used.
  final bool supportsCapturedWidget;

  /// Whether file/URL/bytes image sources are supported.
  final bool supportsDirectImageSources;

  /// Convenience helper: whether the platform can set wallpapers at all.
  bool get supportsWallpaperSetting =>
      supportsHome || supportsLock || supportsBoth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WallpaperCapabilities &&
          other.supportsHome == supportsHome &&
          other.supportsLock == supportsLock &&
          other.supportsBoth == supportsBoth &&
          other.supportsCapturedWidget == supportsCapturedWidget &&
          other.supportsDirectImageSources == supportsDirectImageSources;

  @override
  int get hashCode => Object.hash(
    supportsHome,
    supportsLock,
    supportsBoth,
    supportsCapturedWidget,
    supportsDirectImageSources,
  );

  @override
  String toString() =>
      'WallpaperCapabilities('
      'home: $supportsHome, lock: $supportsLock, both: $supportsBoth, '
      'capturedWidget: $supportsCapturedWidget, directImageSources: $supportsDirectImageSources)';
}

/// How an image should be scaled to fit the screen when optional resizing is
/// applied before setting the wallpaper.
///
/// Pass one of these to `setWallpaperFromFile`, `setWallpaperFromUrl`,
/// `setWallpaperFromBytes` or `setWallpaperFromRepaintBoundary` via the
/// optional `fit` argument. When omitted, the image is handed to the platform
/// unscaled and normal platform wallpaper behaviour applies.
enum WallpaperFit {
  /// Scales the image so it fully covers the target, cropping the overflow.
  cover,

  /// Scales the image so it fits entirely inside the target, letterboxing.
  contain,

  /// Stretches the image to exactly fill the target, possibly distorting it.
  fill;

  /// Maps this enum to the string value understood by the native platform.
  String get nativeValue {
    switch (this) {
      case WallpaperFit.cover:
        return 'cover';
      case WallpaperFit.contain:
        return 'contain';
      case WallpaperFit.fill:
        return 'fill';
    }
  }
}

/// Basic, reliably-available information about the screen or wallpaper area.
@immutable
class WallpaperScreenInfo {
  const WallpaperScreenInfo({
    this.width,
    this.height,
    this.pixelDensity,
    this.orientation,
  });

  /// The reported width in pixels, when available.
  final double? width;

  /// The reported height in pixels, when available.
  final double? height;

  /// The device pixel density, when available.
  final double? pixelDensity;

  /// A short description of the current orientation, when known.
  final String? orientation;

  @override
  String toString() =>
      'WallpaperScreenInfo('
      'width: $width, height: $height, pixelDensity: $pixelDensity, '
      'orientation: $orientation)';
}

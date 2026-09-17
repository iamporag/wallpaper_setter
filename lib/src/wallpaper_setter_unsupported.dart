import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../wallpaper_setter_models.dart';
import '../wallpaper_setter_platform_interface.dart';

/// Dart-only [WallpaperPluginPlatform] for desktop platforms with no native
/// wallpaper-setting integration (Windows, macOS, Linux).
///
/// Every operation resolves gracefully with [WallpaperError.unsupported]
/// instead of throwing, matching this package's iOS fallback behaviour.
class UnsupportedWallpaperPlugin extends WallpaperPluginPlatform {
  /// Registers this implementation as the [WallpaperPluginPlatform.instance]
  /// for the current platform. Invoked automatically by the generated plugin
  /// registrant on platforms that declare `dartPluginClass` for this class.
  static void registerWith() {
    WallpaperPluginPlatform.instance = UnsupportedWallpaperPlugin();
  }

  static const WallpaperResult _unsupportedResult = WallpaperResult.failure(
    WallpaperError.unsupported,
    message: 'Wallpaper setting is not supported on this platform.',
  );

  @override
  Future<WallpaperCapabilities> getCapabilities() async =>
      WallpaperCapabilities.none;

  @override
  Future<WallpaperResult> setWallpaperFromRepaintBoundary(
    GlobalKey boundaryKey,
    WallpaperTarget target, {
    double pixelRatio = 2.5,
    WallpaperFit? fit,
  }) async => _unsupportedResult;

  @override
  Future<WallpaperResult> setWallpaperFromFile(
    File file,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async => _unsupportedResult;

  @override
  Future<WallpaperResult> setWallpaperFromUrl(
    String url,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async => _unsupportedResult;

  @override
  Future<WallpaperResult> setWallpaperFromUri(
    String uri,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async => _unsupportedResult;

  @override
  Future<Uint8List?> getImageBytesFromUri(String uri) async => null;

  @override
  Future<WallpaperResult> setWallpaperFromBytes(
    Uint8List bytes,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async => _unsupportedResult;

  @override
  Future<WallpaperResult> useAsImageFromRepaintBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.5,
  }) async => _unsupportedResult;

  @override
  Future<WallpaperScreenInfo> getScreenInfo() async =>
      const WallpaperScreenInfo();

  @override
  void setIncomingWallpaperHandler(IncomingWallpaperCallback? handler) {
    // No native delivery mechanism exists on this platform; nothing to wire up.
  }
}

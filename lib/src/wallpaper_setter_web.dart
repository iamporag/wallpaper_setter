import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '../wallpaper_setter_models.dart';
import '../wallpaper_setter_platform_interface.dart';

/// Web [WallpaperPluginPlatform] implementation.
///
/// The browser sandbox has no concept of a device wallpaper, so every
/// operation resolves gracefully with [WallpaperError.unsupported] instead
/// of throwing, matching this package's other unsupported-platform fallbacks.
class WallpaperPluginWeb extends WallpaperPluginPlatform {
  /// Registers this implementation as the [WallpaperPluginPlatform.instance]
  /// on web. Invoked automatically by the generated web plugin registrant.
  static void registerWith(Registrar registrar) {
    WallpaperPluginPlatform.instance = WallpaperPluginWeb();
  }

  static const WallpaperResult _unsupportedResult = WallpaperResult.failure(
    WallpaperError.unsupported,
    message: 'Wallpaper setting is not supported on the web.',
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
    // No native delivery mechanism exists on the web; nothing to wire up.
  }
}

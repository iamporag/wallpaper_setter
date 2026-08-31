import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'wallpaper_setter_models.dart';
import 'wallpaper_setter_platform_interface.dart';

export 'wallpaper_setter_models.dart';

/// Entry point for setting device wallpapers.
///
/// v2.0.0 replaces the v1.x `setWallpaperFromRepaintBoundary(GlobalKey, String)`
/// API with a type-safe, result-based API that supports multiple image sources.
class WallpaperPlugin {
  WallpaperPlugin._();

  /// Returns a description of what the current platform supports.
  ///
  /// See [WallpaperCapabilities] for the individual capabilities.
  static Future<WallpaperCapabilities> getCapabilities() {
    return WallpaperPluginPlatform.instance.getCapabilities();
  }

  /// Sets the wallpaper from a [RepaintBoundary] identified by [boundaryKey].
  ///
  /// The widget must be wrapped in a [RepaintBoundary] with [boundaryKey] as
  /// its key so that it can be captured as an image.
  ///
  /// [pixelRatio] controls the capture resolution relative to the logical size
  /// of the widget. [fit] optionally scales the captured image to the screen.
  static Future<WallpaperResult> setWallpaperFromRepaintBoundary(
    GlobalKey boundaryKey,
    WallpaperTarget target, {
    double pixelRatio = 2.5,
    WallpaperFit? fit,
  }) {
    return WallpaperPluginPlatform.instance.setWallpaperFromRepaintBoundary(
      boundaryKey,
      target,
      pixelRatio: pixelRatio,
      fit: fit,
    );
  }

  /// Sets the wallpaper from a [File] containing an image.
  ///
  /// [fit] optionally scales the image to the screen before it is applied.
  static Future<WallpaperResult> setWallpaperFromFile(
    File file,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) {
    return WallpaperPluginPlatform.instance
        .setWallpaperFromFile(file, target, fit: fit);
  }

  /// Sets the wallpaper from a network [url] pointing to an image.
  ///
  /// [fit] optionally scales the image to the screen before it is applied.
  static Future<WallpaperResult> setWallpaperFromUrl(
    String url,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) {
    return WallpaperPluginPlatform.instance
        .setWallpaperFromUrl(url, target, fit: fit);
  }

  /// Sets the wallpaper from raw encoded image [bytes] (JPEG/PNG).
  ///
  /// [fit] optionally scales the image to the screen before it is applied.
  static Future<WallpaperResult> setWallpaperFromBytes(
    Uint8List bytes,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) {
    return WallpaperPluginPlatform.instance
        .setWallpaperFromBytes(bytes, target, fit: fit);
  }

  /// Shares / uses an image captured from a [RepaintBoundary].
  ///
  /// This is the primary option on platforms (such as iOS) where wallpaper
  /// cannot be set programmatically.
  static Future<WallpaperResult> useAsImageFromRepaintBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.5,
  }) {
    return WallpaperPluginPlatform.instance.useAsImageFromRepaintBoundary(
      boundaryKey,
      pixelRatio: pixelRatio,
    );
  }

  /// Returns basic screen / wallpaper information when reliably available.
  static Future<WallpaperScreenInfo> getScreenInfo() {
    return WallpaperPluginPlatform.instance.getScreenInfo();
  }
}

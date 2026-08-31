import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wallpaper_setter_method_channel.dart';
import 'wallpaper_setter_models.dart';

/// Platform interface for [wallpaper_setter].
///
/// All wallpaper operations are routed through an instance of this interface,
/// which allows the implementation to be swapped out (for example, in tests).
abstract class WallpaperPluginPlatform extends PlatformInterface {
  WallpaperPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static WallpaperPluginPlatform _instance = MethodChannelWallpaperPlugin();

  static WallpaperPluginPlatform get instance => _instance;

  static set instance(WallpaperPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the capabilities supported by the current platform.
  Future<WallpaperCapabilities> getCapabilities() {
    throw UnimplementedError('getCapabilities() has not been implemented.');
  }

  /// Sets the wallpaper from a [RepaintBoundary] identified by [boundaryKey].
  Future<WallpaperResult> setWallpaperFromRepaintBoundary(
    GlobalKey boundaryKey,
    WallpaperTarget target, {
    double pixelRatio = 2.5,
    WallpaperFit? fit,
  }) {
    throw UnimplementedError(
        'setWallpaperFromRepaintBoundary() has not been implemented.');
  }

  /// Sets the wallpaper from an image [file].
  Future<WallpaperResult> setWallpaperFromFile(
    File file,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) {
    throw UnimplementedError('setWallpaperFromFile() has not been implemented.');
  }

  /// Sets the wallpaper from a network [url].
  Future<WallpaperResult> setWallpaperFromUrl(
    String url,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) {
    throw UnimplementedError('setWallpaperFromUrl() has not been implemented.');
  }

  /// Sets the wallpaper from raw image [bytes].
  Future<WallpaperResult> setWallpaperFromBytes(
    Uint8List bytes,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) {
    throw UnimplementedError(
        'setWallpaperFromBytes() has not been implemented.');
  }

  /// Shares / uses an image captured from a [RepaintBoundary].
  Future<WallpaperResult> useAsImageFromRepaintBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.5,
  }) {
    throw UnimplementedError(
        'useAsImageFromRepaintBoundary() has not been implemented.');
  }

  /// Returns basic screen / wallpaper information when reliably available.
  Future<WallpaperScreenInfo> getScreenInfo() {
    throw UnimplementedError('getScreenInfo() has not been implemented.');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dart:ui';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class WallpaperPlugin {
  static const MethodChannel _channel = MethodChannel('com.iamporag/wallpaper');

  Future<String?> getPlatformVersion() async {
    final version = await _channel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  /// Capture widget boundary and set it as wallpaper
  static Future<bool> setWallpaperFromRepaintBoundary(
    GlobalKey boundaryKey,
    String target, {
    double pixelRatio = 2.5,
  }) async {
    try {
      final RenderRepaintBoundary boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(
        format: ImageByteFormat.png,
      );
      final Uint8List bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/wallpaper.png';
      final file = File(filePath)..writeAsBytesSync(bytes);

      final bool success = await _channel.invokeMethod('setWallpaper', {
        'path': file.path,
        'target': target,
      });

      return success;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Use an image as wallpaper via system share
  static Future<bool> useAsImageFromRepaintBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.5,
  }) async {
    try {
      final RenderRepaintBoundary boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(
        format: ImageByteFormat.png,
      );
      final Uint8List bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/use_as_temp.png';
      final file = File(filePath)..writeAsBytesSync(bytes);

      await _channel.invokeMethod('useAsImage', {'path': file.path});
      return true;
    } on PlatformException catch (_) {
      return false;
    }
  }
}

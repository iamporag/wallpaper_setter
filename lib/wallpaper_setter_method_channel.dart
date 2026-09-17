import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'wallpaper_setter_models.dart';
import 'wallpaper_setter_platform_interface.dart';

/// MethodChannel-backed implementation of [WallpaperPluginPlatform].
class MethodChannelWallpaperPlugin extends WallpaperPluginPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('com.iamporag/wallpaper');

  /// Native → Dart channel used to deliver an incoming image URI from an
  /// external "Use as → Wallpaper" intent.
  final incomingChannel = const MethodChannel('com.iamporag/wallpaper_incoming');

  IncomingWallpaperCallback? _incomingCallback;

  @override
  void setIncomingWallpaperHandler(IncomingWallpaperCallback? handler) {
    _incomingCallback = handler;
    if (handler != null) {
      incomingChannel.setMethodCallHandler(_onIncomingCall);
      // Pick up any URI that arrived before the handler was registered
      // (e.g. a cold-start intent delivered before the first frame).
      _pollPendingIncomingImage();
    } else {
      incomingChannel.setMethodCallHandler(null);
    }
  }

  Future<void> _pollPendingIncomingImage() async {
    final callback = _incomingCallback;
    if (callback == null) return;
    try {
      final pending = await methodChannel.invokeMethod<String>(
        'getPendingIncomingImage',
      );
      if (pending != null && pending.isNotEmpty) {
        callback(pending);
      }
    } on PlatformException {
      // Not supported on this platform; ignore.
    } on MissingPluginException {
      // Plugin not available in this context (e.g. during tests).
    }
  }

  Future<dynamic> _onIncomingCall(MethodCall call) async {
    switch (call.method) {
      case 'incomingImage':
        final uri = call.arguments;
        final callback = _incomingCallback;
        if (callback != null && uri is String && uri.isNotEmpty) {
          callback(uri);
        }
        return null;
      default:
        throw MissingPluginException(
            'No handler for incoming method ${call.method}');
    }
  }
  @override
  Future<WallpaperCapabilities> getCapabilities() async {
    try {
      final raw = await methodChannel.invokeMapMethod<String, dynamic>(
        'getCapabilities',
      );
      if (raw == null) return WallpaperCapabilities.none;

      return WallpaperCapabilities(
        supportsHome: raw['home'] as bool? ?? false,
        supportsLock: raw['lock'] as bool? ?? false,
        supportsBoth: raw['both'] as bool? ?? false,
        supportsCapturedWidget: raw['capturedWidget'] as bool? ?? false,
        supportsDirectImageSources: raw['directImageSources'] as bool? ?? false,
      );
    } on PlatformException catch (e) {
      debugPrint('getCapabilities error: ${e.message}');
      return WallpaperCapabilities.none;
    }
  }

  @override
  Future<WallpaperResult> setWallpaperFromRepaintBoundary(
    GlobalKey boundaryKey,
    WallpaperTarget target, {
    double pixelRatio = 2.5,
    WallpaperFit? fit,
  }) async {
    try {
      final bytes = await _captureWidget(boundaryKey, pixelRatio);
      if (bytes == null) {
        return WallpaperResult.failure(
          WallpaperError.invalidImage,
          message: 'Could not capture the RepaintBoundary widget.',
        );
      }
      return await _setWallpaperBytes(bytes, target, fit: fit);
    } catch (e) {
      return WallpaperResult.failure(
        WallpaperError.platformError,
        message: 'Failed to capture or set wallpaper: $e',
      );
    }
  }

  @override
  Future<WallpaperResult> setWallpaperFromFile(
    File file,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    try {
      if (!await file.exists()) {
        return WallpaperResult.failure(
          WallpaperError.fileError,
          message: 'Image file does not exist: ${file.path}',
        );
      }
      final bytes = await file.readAsBytes();
      return await _setWallpaperBytes(bytes, target, fit: fit);
    } catch (e) {
      return WallpaperResult.failure(
        WallpaperError.fileError,
        message: 'Failed to read image file: $e',
      );
    }
  }

  @override
  Future<WallpaperResult> setWallpaperFromUrl(
    String url,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    try {
      final bytes = await _downloadBytes(url);
      return await _setWallpaperBytes(bytes, target, fit: fit);
    } on WallpaperResult catch (result) {
      // _downloadBytes reports expected failures (bad status, empty body) by
      // throwing a WallpaperResult. Surface it as the operation's result rather
      // than letting it escape as an exception.
      return result;
    } catch (e) {
      return WallpaperResult.failure(
        WallpaperError.networkError,
        message: 'Failed to download image from URL: $e',
      );
    }
  }

  @override
  Future<WallpaperResult> setWallpaperFromBytes(
    Uint8List bytes,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    if (bytes.isEmpty) {
      return WallpaperResult.failure(
        WallpaperError.invalidImage,
        message: 'Image bytes are empty.',
      );
    }
    return await _setWallpaperBytes(bytes, target, fit: fit);
  }

  /// Sets the wallpaper from a `content://` URI supplied by an external app.
  ///
  /// The URI is read natively (via ContentResolver) — it is never converted to
  /// a filesystem path, since `content://` URIs generally do not map to a path.
  @override
  Future<WallpaperResult> setWallpaperFromUri(
    String uri,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    try {
      final raw =
          await methodChannel.invokeMethod<dynamic>('setWallpaperFromUri', {
            'uri': uri,
            'target': target.nativeValue,
            if (fit != null) 'fit': fit.nativeValue,
          });
      if (raw is Map) {
        return _resultFromMap(raw);
      }
      return _resultFromMap({
        'isSuccess': false,
        'error': WallpaperError.platformError.nativeValue,
        'message': 'Failed to set wallpaper from URI.',
      });
    } on PlatformException catch (e) {
      return _resultFromPlatformException(e);
    }
  }

  @override
  Future<Uint8List?> getImageBytesFromUri(String uri) async {
    try {
      final bytes = await methodChannel.invokeMethod<Uint8List>(
        'getImageBytesFromUri',
        {'uri': uri},
      );
      return bytes;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<WallpaperResult> useAsImageFromRepaintBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.5,
  }) async {
    try {
      final bytes = await _captureWidget(boundaryKey, pixelRatio);
      if (bytes == null) {
        return WallpaperResult.failure(
          WallpaperError.invalidImage,
          message: 'Could not capture the RepaintBoundary widget.',
        );
      }
      return await _useAsImageBytes(bytes);
    } catch (e) {
      return WallpaperResult.failure(
        WallpaperError.platformError,
        message: 'Failed to use image: $e',
      );
    }
  }

  @override
  Future<WallpaperScreenInfo> getScreenInfo() async {
    try {
      final raw = await methodChannel.invokeMapMethod<String, dynamic>(
        'getScreenInfo',
      );
      if (raw == null) return const WallpaperScreenInfo();

      return WallpaperScreenInfo(
        width: (raw['width'] as num?)?.toDouble(),
        height: (raw['height'] as num?)?.toDouble(),
        pixelDensity: (raw['pixelDensity'] as num?)?.toDouble(),
        orientation: raw['orientation'] as String?,
      );
    } on PlatformException catch (e) {
      debugPrint('getScreenInfo error: ${e.message}');
      return const WallpaperScreenInfo();
    }
  }

  // ---------------------------------------------------------------------------
  // Shared pipeline
  // ---------------------------------------------------------------------------

  Future<WallpaperResult> _setWallpaperBytes(
    Uint8List bytes,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    final file = await _saveTempFile(bytes, 'wallpaper');
    try {
      final raw = await methodChannel.invokeMethod<dynamic>('setWallpaper', {
        'path': file.path,
        'target': target.nativeValue,
        if (fit != null) 'fit': fit.nativeValue,
      });

      if (raw is Map) {
        return _resultFromMap(raw);
      }
      if (raw is bool && raw == true) {
        return const WallpaperResult.success(
          message: 'Wallpaper set successfully.',
        );
      }
      return _resultFromMap({
        'isSuccess': raw,
        'error': WallpaperError.platformError.nativeValue,
        'message': 'Failed to set wallpaper.',
      });
    } on PlatformException catch (e) {
      return _resultFromPlatformException(e);
    } finally {
      await _deleteFile(file);
    }
  }

  Future<WallpaperResult> _useAsImageBytes(Uint8List bytes) async {
    final file = await _saveTempFile(bytes, 'use_as_temp');
    try {
      final raw = await methodChannel.invokeMethod<dynamic>('useAsImage', {
        'path': file.path,
      });

      // NOTE: Do NOT delete the temp file here. On Android the external app
      // that receives ACTION_ATTACH_DATA reads the image file asynchronously
      // after the chooser/intent is launched. Deleting it immediately would
      // hand the receiving app a content URI pointing to a missing file, which
      // makes it hang on "loading" forever and never save/show the wallpaper.
      // The file lives in the cache dir, so the OS reclaims it as needed.
      if (raw is Map) {
        return _resultFromMap(raw);
      }
      return const WallpaperResult.success(message: 'Use-as launched.');
    } on PlatformException catch (e) {
      await _deleteFile(file);
      return _resultFromPlatformException(e);
    }
  }

  WallpaperResult _resultFromMap(Map<dynamic, dynamic> map) {
    final isSuccess = map['isSuccess'] as bool? ?? false;
    final error = WallpaperErrorExtension.fromNativeValue(map['error']);
    final message = map['message'] as String?;
    if (isSuccess) {
      return WallpaperResult.success(message: message);
    }
    return WallpaperResult.failure(
      error ?? WallpaperError.platformError,
      message: message,
    );
  }

  WallpaperResult _resultFromPlatformException(PlatformException e) {
    final error = _errorFromCode(e.code);
    return WallpaperResult.failure(error, message: e.message);
  }

  WallpaperError _errorFromCode(String code) {
    switch (code) {
      case 'UNSUPPORTED':
        return WallpaperError.unsupported;
      case 'INVALID_IMAGE':
      case 'DECODE_FAILED':
        return WallpaperError.invalidImage;
      case 'PERMISSION_DENIED':
        return WallpaperError.permissionDenied;
      case 'NETWORK_ERROR':
        return WallpaperError.networkError;
      case 'FILE_ERROR':
        return WallpaperError.fileError;
      case 'PLATFORM_ERROR':
      case 'UNAVAILABLE':
        return WallpaperError.platformError;
      default:
        return WallpaperError.unknown;
    }
  }

  Future<Uint8List?> _captureWidget(GlobalKey key, double pixelRatio) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Widget capture error: $e');
      return null;
    }
  }

  /// Generous ceiling so slow-but-steady downloads still succeed while a
  /// stalled connection fails with a [WallpaperResult.networkError] instead of
  /// spinning indefinitely.
  static const Duration _downloadTimeout = Duration(seconds: 30);

  Future<Uint8List> _downloadBytes(String url) async {
    final client = HttpClient();
    try {
      client.connectionTimeout = _downloadTimeout;
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(_downloadTimeout);
      final response = await request.close().timeout(_downloadTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw WallpaperResult.failure(
          WallpaperError.networkError,
          message: 'Failed to download image (HTTP ${response.statusCode}).',
        );
      }
      final body = await consolidateHttpClientResponseBytes(response).timeout(
        _downloadTimeout,
      );
      if (body.isEmpty) {
        throw const WallpaperResult.failure(
          WallpaperError.networkError,
          message: 'Downloaded image is empty.',
        );
      }
      return body;
    } finally {
      client.close();
    }
  }

  Future<File> _saveTempFile(Uint8List bytes, String name) async {
    final tempDir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/${name}_$stamp.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Temp file cleanup failed: $e');
    }
  }
}

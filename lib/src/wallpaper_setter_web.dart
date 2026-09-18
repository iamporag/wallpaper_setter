import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import '../wallpaper_setter_models.dart';
import '../wallpaper_setter_platform_interface.dart';

/// Web implementation of [WallpaperPluginPlatform].
///
/// Browsers cannot set device wallpapers programmatically. This implementation
/// provides web-compatible alternatives:
///
/// - **CSS body background-image** — sets the browser page background as a
///   visual wallpaper effect.
/// - **Image download** — triggers a browser download so users can save the
///   image and set it as their device wallpaper manually.
/// - **Screen info** — reports viewport and device pixel ratio via Web APIs.
class WallpaperPluginWeb extends WallpaperPluginPlatform {
  /// Registers this implementation as the [WallpaperPluginPlatform.instance]
  /// on web. Invoked automatically by the generated web plugin registrant.
  static void registerWith(Registrar registrar) {
    WallpaperPluginPlatform.instance = WallpaperPluginWeb();
  }

  @override
  Future<WallpaperCapabilities> getCapabilities() async {
    return const WallpaperCapabilities(
      supportsHome: false,
      supportsLock: false,
      supportsBoth: false,
      supportsCapturedWidget: false,
      supportsDirectImageSources: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Wallpaper setters
  // ---------------------------------------------------------------------------

  @override
  Future<WallpaperResult> setWallpaperFromUrl(
    String url,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    try {
      _setBodyBackground(url, fit);
      return const WallpaperResult.success(
        message:
            'Page background updated. Right-click the page to save the image.',
      );
    } catch (e) {
      return WallpaperResult.failure(
        WallpaperError.platformError,
        message: 'Failed to apply background: $e',
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
      return const WallpaperResult.failure(
        WallpaperError.invalidImage,
        message: 'Image bytes are empty.',
      );
    }
    try {
      final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
      _setBodyBackground(dataUrl, fit);
      return const WallpaperResult.success(
        message: 'Page background updated from image data.',
      );
    } catch (e) {
      return WallpaperResult.failure(
        WallpaperError.platformError,
        message: 'Failed to apply background: $e',
      );
    }
  }

  @override
  Future<WallpaperResult> setWallpaperFromFile(
    File file,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    return const WallpaperResult.failure(
      WallpaperError.unsupported,
      message:
          'File-based wallpaper is not supported on web. Use image URL or bytes.',
    );
  }

  @override
  Future<WallpaperResult> setWallpaperFromUri(
    String uri,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    return const WallpaperResult.failure(
      WallpaperError.unsupported,
      message: 'URI-based wallpaper is not supported on web.',
    );
  }

  @override
  Future<WallpaperResult> setWallpaperFromRepaintBoundary(
    GlobalKey boundaryKey,
    WallpaperTarget target, {
    double pixelRatio = 2.5,
    WallpaperFit? fit,
  }) async {
    return const WallpaperResult.failure(
      WallpaperError.unsupported,
      message:
          'Widget capture is not supported on web. Use image URL or bytes.',
    );
  }

  @override
  Future<WallpaperResult> useAsImageFromRepaintBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.5,
  }) async {
    return const WallpaperResult.failure(
      WallpaperError.unsupported,
      message: 'Widget capture is not supported on web.',
    );
  }

  @override
  Future<Uint8List?> getImageBytesFromUri(String uri) async => null;

  // ---------------------------------------------------------------------------
  // Screen info
  // ---------------------------------------------------------------------------

  @override
  Future<WallpaperScreenInfo> getScreenInfo() async {
    final screen = web.window.screen;
    final dpr = web.window.devicePixelRatio;
    return WallpaperScreenInfo(
      width: screen.width.toDouble(),
      height: screen.height.toDouble(),
      pixelDensity: dpr.toDouble(),
      orientation: web.window.innerWidth > web.window.innerHeight
          ? 'landscape'
          : 'portrait',
    );
  }

  // ---------------------------------------------------------------------------
  // Incoming wallpaper handler (no-op on web)
  // ---------------------------------------------------------------------------

  @override
  void setIncomingWallpaperHandler(IncomingWallpaperCallback? handler) {
    // No native delivery mechanism on web.
  }

  // ---------------------------------------------------------------------------
  // Web helpers – exposed publicly so the example / consumer can use them.
  // ---------------------------------------------------------------------------

  /// Sets the browser page `<body>` background image to [url].
  void setBodyBackgroundFromUrl(String url, {WallpaperFit? fit}) {
    _setBodyBackground(url, fit);
  }

  /// Triggers a browser file download for the image at [url].
  void downloadImage(String url, {String filename = 'wallpaper.png'}) {
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = filename
      ..style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }

  /// Triggers a browser file download for raw image [bytes] (encoded as PNG).
  void downloadImageBytes(
    Uint8List bytes, {
    String filename = 'wallpaper.png',
  }) {
    final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
    downloadImage(dataUrl, filename: filename);
  }

  /// Requests full-screen mode for the document root element.
  ///
  /// Browsers may restrict fullscreen to user-gesture contexts.
  Future<void> requestFullscreen() async {
    try {
      web.document.documentElement?.requestFullscreen();
    } catch (_) {
      // Fullscreen not supported or denied by the browser.
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _setBodyBackground(String url, WallpaperFit? fit) {
    final body = web.document.body;
    if (body == null) return;

    final size = switch (fit) {
      WallpaperFit.cover => 'cover',
      WallpaperFit.contain => 'contain',
      WallpaperFit.fill => '100% 100%',
      null => 'cover',
    };

    body.style
      ..backgroundImage = 'url("$url")'
      ..backgroundSize = size
      ..backgroundPosition = 'center center'
      ..backgroundRepeat = 'no-repeat'
      ..backgroundAttachment = 'fixed'
      ..margin = '0';
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wallpaper_setter/wallpaper_setter.dart';
import 'package:wallpaper_setter/wallpaper_setter_method_channel.dart';
import 'package:wallpaper_setter/wallpaper_setter_platform_interface.dart';

class MockWallpaperPluginPlatform extends MockPlatformInterfaceMixin
    implements WallpaperPluginPlatform {
  @override
  Future<WallpaperCapabilities> getCapabilities() async {
    return const WallpaperCapabilities(
      supportsHome: true,
      supportsLock: true,
      supportsBoth: true,
      supportsCapturedWidget: true,
      supportsDirectImageSources: true,
    );
  }

  @override
  Future<WallpaperResult> setWallpaperFromRepaintBoundary(
    GlobalKey boundaryKey,
    WallpaperTarget target, {
    double pixelRatio = 2.5,
    WallpaperFit? fit,
  }) async {
    return const WallpaperResult.success(message: 'captured');
  }

  @override
  Future<WallpaperResult> setWallpaperFromFile(
    File file,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    return const WallpaperResult.success(message: 'file');
  }

  @override
  Future<WallpaperResult> setWallpaperFromUrl(
    String url,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    return const WallpaperResult.success(message: 'url');
  }

  @override
  Future<WallpaperResult> setWallpaperFromBytes(
    Uint8List bytes,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    return const WallpaperResult.success(message: 'bytes');
  }

  @override
  Future<WallpaperResult> useAsImageFromRepaintBoundary(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.5,
  }) async {
    return const WallpaperResult.success(message: 'use-as');
  }

  @override
  Future<WallpaperScreenInfo> getScreenInfo() async {
    return const WallpaperScreenInfo(width: 100, height: 200);
  }

  @override
  Future<WallpaperResult> setWallpaperFromUri(
    String uri,
    WallpaperTarget target, {
    WallpaperFit? fit,
  }) async {
    return const WallpaperResult.success(message: 'uri');
  }

  @override
  Future<Uint8List?> getImageBytesFromUri(String uri) async => null;

  @override
  void setIncomingWallpaperHandler(IncomingWallpaperCallback? handler) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('$MethodChannelWallpaperPlugin is the default instance', () {
    expect(
      WallpaperPluginPlatform.instance,
      isInstanceOf<MethodChannelWallpaperPlugin>(),
    );
  });

  test('getCapabilities routes to platform instance', () async {
    final fake = MockWallpaperPluginPlatform();
    WallpaperPluginPlatform.instance = fake;

    final caps = await WallpaperPlugin.getCapabilities();
    expect(caps.supportsHome, isTrue);
    expect(caps.supportsLock, isTrue);
    expect(caps.supportsBoth, isTrue);
    expect(caps.supportsCapturedWidget, isTrue);
  });

  test('setWallpaperFromBytes routes through instance', () async {
    final fake = MockWallpaperPluginPlatform();
    WallpaperPluginPlatform.instance = fake;

    final result = await WallpaperPlugin.setWallpaperFromBytes(
      Uint8List.fromList([1, 2, 3]),
      WallpaperTarget.home,
    );
    expect(result.isSuccess, isTrue);
    expect(result.message, 'bytes');
  });

  test('setWallpaperFromUrl routes through instance', () async {
    final fake = MockWallpaperPluginPlatform();
    WallpaperPluginPlatform.instance = fake;

    final result = await WallpaperPlugin.setWallpaperFromUrl(
      'https://example.com/a.png',
      WallpaperTarget.both,
    );
    expect(result.isSuccess, isTrue);
  });

  test('setWallpaperFromFile routes through instance', () async {
    final fake = MockWallpaperPluginPlatform();
    WallpaperPluginPlatform.instance = fake;

    final result = await WallpaperPlugin.setWallpaperFromFile(
      File('/tmp/wallpaper.png'),
      WallpaperTarget.lock,
    );
    expect(result.isSuccess, isTrue);
    expect(result.message, 'file');
  });

  test('setWallpaperFromRepaintBoundary routes through instance', () async {
    final fake = MockWallpaperPluginPlatform();
    WallpaperPluginPlatform.instance = fake;

    final key = GlobalKey();
    final result = await WallpaperPlugin.setWallpaperFromRepaintBoundary(
      key,
      WallpaperTarget.home,
    );
    expect(result.isSuccess, isTrue);
    expect(result.message, 'captured');
  });

  test('useAsImageFromRepaintBoundary routes through instance', () async {
    final fake = MockWallpaperPluginPlatform();
    WallpaperPluginPlatform.instance = fake;

    final key = GlobalKey();
    final result = await WallpaperPlugin.useAsImageFromRepaintBoundary(key);
    expect(result.isSuccess, isTrue);
    expect(result.message, 'use-as');
  });

  test('setWallpaperFromBytes accepts an optional fit', () async {
    final fake = MockWallpaperPluginPlatform();
    WallpaperPluginPlatform.instance = fake;

    final result = await WallpaperPlugin.setWallpaperFromBytes(
      Uint8List.fromList([1, 2, 3]),
      WallpaperTarget.home,
      fit: WallpaperFit.cover,
    );
    expect(result.isSuccess, isTrue);
  });

  test('getScreenInfo routes through instance', () async {
    final fake = MockWallpaperPluginPlatform();
    WallpaperPluginPlatform.instance = fake;

    final info = await WallpaperPlugin.getScreenInfo();
    expect(info.width, 100);
    expect(info.height, 200);
  });

  test('public API exposes result/error types', () {
    expect(WallpaperTarget.values, hasLength(3));
    expect(WallpaperError.values, contains(WallpaperError.unknown));
    expect(WallpaperResult.success(), isA<WallpaperResult>());
    expect(WallpaperCapabilities.none, isA<WallpaperCapabilities>());
  });
}

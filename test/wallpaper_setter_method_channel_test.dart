import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:wallpaper_setter/wallpaper_setter_method_channel.dart';
import 'package:wallpaper_setter/wallpaper_setter_models.dart';

/// A [PathProviderPlatform] that reports a fixed temporary directory so temp
/// file creation/cleanup can be verified deterministically in tests.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.tempDir);

  final Directory tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final plugin = MethodChannelWallpaperPlugin();
  const channel = MethodChannel('com.iamporag/wallpaper');

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('wallpaper_setter_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getCapabilities':
              return {
                'home': true,
                'lock': false,
                'both': false,
                'capturedWidget': true,
                'directImageSources': true,
              };
            case 'getScreenInfo':
              return {
                'width': 1080.0,
                'height': 2340.0,
                'pixelDensity': 3.0,
                'orientation': 'portrait',
              };
            case 'setWallpaper':
              return {
                'isSuccess': true,
                'message': 'Wallpaper set successfully.',
              };
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  final bytes = Uint8List.fromList([1, 2, 3]);

  test('getCapabilities maps native map', () async {
    final caps = await plugin.getCapabilities();
    expect(caps.supportsHome, isTrue);
    expect(caps.supportsLock, isFalse);
    expect(caps.supportsBoth, isFalse);
    expect(caps.supportsCapturedWidget, isTrue);
    expect(caps.supportsDirectImageSources, isTrue);
  });

  test('getScreenInfo maps native map', () async {
    final info = await plugin.getScreenInfo();
    expect(info.width, 1080.0);
    expect(info.height, 2340.0);
    expect(info.pixelDensity, 3.0);
    expect(info.orientation, 'portrait');
  });

  test('getCapabilities returns none on platform exception', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(code: 'BOOM', message: 'boom');
        });

    final caps = await plugin.getCapabilities();
    expect(caps.supportsWallpaperSetting, isFalse);
  });

  test(
    'setWallpaperFromBytes with empty bytes fails with invalidImage',
    () async {
      final result = await plugin.setWallpaperFromBytes(
        Uint8List(0),
        WallpaperTarget.home,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, WallpaperError.invalidImage);
      expect(tempDir.listSync(), isEmpty);
    },
  );

  test(
    'setWallpaperFromBytes forwards target and passes through success',
    () async {
      final seen = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            seen.add(call.method);
            expect(call.arguments['target'], 'lock');
            expect(call.arguments['path'], isA<String>());
            return {
              'isSuccess': true,
              'message': 'Wallpaper set successfully.',
            };
          });

      final result = await plugin.setWallpaperFromBytes(
        bytes,
        WallpaperTarget.lock,
      );

      expect(seen, ['setWallpaper']);
      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
    },
  );

  test('setWallpaperFromBytes cleans up the temporary file', () async {
    await plugin.setWallpaperFromBytes(bytes, WallpaperTarget.home);

    expect(tempDir.listSync(), isEmpty);
  });

  test('setWallpaperFromBytes forwards fit when provided', () async {
    late Map<Object?, Object?> args;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          args = call.arguments as Map<Object?, Object?>;
          return {'isSuccess': true};
        });

    await plugin.setWallpaperFromBytes(
      bytes,
      WallpaperTarget.home,
      fit: WallpaperFit.cover,
    );

    expect(args['fit'], 'cover');
  });

  test('setWallpaperFromBytes omits fit when not provided', () async {
    late Map<Object?, Object?> args;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          args = call.arguments as Map<Object?, Object?>;
          return {'isSuccess': true};
        });

    await plugin.setWallpaperFromBytes(bytes, WallpaperTarget.home);

    expect(args.containsKey('fit'), isFalse);
  });

  test('setWallpaperFromFile with missing file fails with fileError', () async {
    final result = await plugin.setWallpaperFromFile(
      File('/nonexistent/does_not_exist.png'),
      WallpaperTarget.home,
    );

    expect(result.isSuccess, isFalse);
    expect(result.error, WallpaperError.fileError);
  });

  test('setWallpaperFromFile with existing file succeeds', () async {
    final sourceFile = File('${tempDir.path}/source.png')
      ..writeAsBytesSync([1, 2, 3]);

    final result = await plugin.setWallpaperFromFile(
      sourceFile,
      WallpaperTarget.home,
    );

    expect(result.isSuccess, isTrue);
    final leftover = tempDir
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .where((p) => p.endsWith('_wallpaper.png'));
    expect(leftover, isEmpty);
  });

  test(
    'setWallpaperFromUrl surfaces a WallpaperResult instead of throwing',
    () async {
      final result = await plugin.setWallpaperFromUrl(
        'https://example.com/wallpaper.png',
        WallpaperTarget.both,
      );

      expect(result, isA<WallpaperResult>());
      expect(result.isSuccess, isFalse);
      expect(result.error, WallpaperError.networkError);
    },
  );

  test('maps PlatformException code to the matching WallpaperError', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          throw PlatformException(
            code: 'UNSUPPORTED',
            message: 'not supported here',
          );
        });

    final result = await plugin.setWallpaperFromBytes(
      bytes,
      WallpaperTarget.home,
    );

    expect(result.isSuccess, isFalse);
    expect(result.error, WallpaperError.unsupported);
    expect(result.message, 'not supported here');
  });

  test('maps failure result map into a WallpaperResult', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          return {
            'isSuccess': false,
            'error': 'permissionDenied',
            'message': 'blocked',
          };
        });

    final result = await plugin.setWallpaperFromBytes(
      bytes,
      WallpaperTarget.home,
    );

    expect(result.isSuccess, isFalse);
    expect(result.error, WallpaperError.permissionDenied);
    expect(result.message, 'blocked');
  });
}

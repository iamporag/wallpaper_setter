import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_setter/wallpaper_setter.dart';

void main() {
  group('WallpaperTarget', () {
    test('supports all expected values', () {
      expect(WallpaperTarget.values, const [
        WallpaperTarget.home,
        WallpaperTarget.lock,
        WallpaperTarget.both,
      ]);
    });

    test('maps to correct native values', () {
      expect(WallpaperTarget.home.nativeValue, 'home');
      expect(WallpaperTarget.lock.nativeValue, 'lock');
      expect(WallpaperTarget.both.nativeValue, 'both');
    });

    test('fromNativeValue resolves valid values', () {
      expect(WallpaperTarget.fromNativeValue('home'), WallpaperTarget.home);
      expect(WallpaperTarget.fromNativeValue('lock'), WallpaperTarget.lock);
      expect(WallpaperTarget.fromNativeValue('both'), WallpaperTarget.both);
    });

    test('fromNativeValue falls back to home for unknown/null', () {
      expect(WallpaperTarget.fromNativeValue('bogus'), WallpaperTarget.home);
      expect(WallpaperTarget.fromNativeValue(null), WallpaperTarget.home);
    });
  });

  group('WallpaperResult', () {
    test('success result', () {
      const result = WallpaperResult.success(message: 'ok');
      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
      expect(result.message, 'ok');
    });

    test('failure result', () {
      const result = WallpaperResult.failure(
        WallpaperError.unsupported,
        message: 'no',
      );
      expect(result.isSuccess, isFalse);
      expect(result.error, WallpaperError.unsupported);
      expect(result.message, 'no');
    });

    test('equality', () {
      const a = WallpaperResult.success(message: 'x');
      const b = WallpaperResult.success(message: 'x');
      const c = WallpaperResult.success(message: 'y');
      expect(a, b);
      expect(a == c, isFalse);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('WallpaperError', () {
    test('contains all known errors', () {
      expect(
        WallpaperError.values,
        containsAll([
          WallpaperError.unsupported,
          WallpaperError.invalidImage,
          WallpaperError.permissionDenied,
          WallpaperError.platformError,
          WallpaperError.networkError,
          WallpaperError.fileError,
          WallpaperError.unknown,
        ]),
      );
    });

    test('nativeValue round-trips', () {
      for (final e in WallpaperError.values) {
        expect(WallpaperErrorExtension.fromNativeValue(e.nativeValue), e);
      }
    });
  });

  group('WallpaperFit', () {
    test('supports all expected values', () {
      expect(WallpaperFit.values, const [
        WallpaperFit.cover,
        WallpaperFit.contain,
        WallpaperFit.fill,
      ]);
    });

    test('maps to correct native values', () {
      expect(WallpaperFit.cover.nativeValue, 'cover');
      expect(WallpaperFit.contain.nativeValue, 'contain');
      expect(WallpaperFit.fill.nativeValue, 'fill');
    });
  });

  group('WallpaperCapabilities', () {
    test('none reports no support', () {
      final none = WallpaperCapabilities.none;
      expect(none.supportsWallpaperSetting, isFalse);
      expect(none.supportsHome, isFalse);
      expect(none.supportsLock, isFalse);
    });
  });
}

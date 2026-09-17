import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter/material.dart';
import 'package:wallpaper_setter/wallpaper_setter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('setWallpaperFromRepaintBoundary returns a WallpaperResult', (
    WidgetTester tester,
  ) async {
    final GlobalKey boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: Container(width: 100, height: 100, color: Colors.blue),
        ),
      ),
    );

    final result = await WallpaperPlugin.setWallpaperFromRepaintBoundary(
      boundaryKey,
      WallpaperTarget.home,
    );

    expect(result, isA<WallpaperResult>());
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter/material.dart';
import 'package:wallpaper_setter/wallpaper_setter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('setWallpaperFromRepaintBoundary returns bool', (
    WidgetTester tester,
  ) async {
    // এখানে একটা dummy widget বানাচ্ছি যা capture করা যাবে
    final GlobalKey boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: Container(width: 100, height: 100, color: Colors.blue),
        ),
      ),
    );

    // ওয়ালপেপার সেট করার মেথড কল করো
    final success = await WallpaperPlugin.setWallpaperFromRepaintBoundary(
      boundaryKey,
      'home',
    );

    // ফলাফল bool হবে, তাই আমরা assert করবো সেটা boolean এবং true/false যেকোনো হতে পারে
    expect(success, isA<bool>());
  });
}

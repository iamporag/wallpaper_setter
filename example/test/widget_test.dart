import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallpaper_setter_example/main.dart';

void main() {
  testWidgets('Home screen renders the wallpaper grid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Select a Wallpaper'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Demo File'), findsOneWidget);
    expect(find.text('Nature'), findsOneWidget);
  });

  testWidgets('Tapping a wallpaper opens the preview screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('Demo File'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // In a widget test the platform channel is unavailable, so capabilities
    // report "none" and the app shows the platform-aware fallback UI.
    expect(find.text('Use As...'), findsOneWidget);
    expect(
      find.textContaining('cannot be set programmatically'),
      findsOneWidget,
    );
  });
}

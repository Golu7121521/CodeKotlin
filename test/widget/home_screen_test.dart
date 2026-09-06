import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:all_video_downloader/providers/downloads_provider.dart';
import 'package:all_video_downloader/providers/settings_provider.dart';
import 'package:all_video_downloader/screens/home_screen.dart';

void main() {
  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DownloadsProvider()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  testWidgets('HomeScreen renders URL input and primary action button', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(find.text('All Video Downloader'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Preview & Download'), findsOneWidget);
  });

  testWidgets('HomeScreen shows bottom navigation with four destinations', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Primary action button is disabled when URL field is empty', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final buttonFinder = find.widgetWithText(FilledButton, 'Preview & Download');
    final button = tester.widget<FilledButton>(buttonFinder);
    expect(button.onPressed, isNull);
  });

  testWidgets('Typing a URL enables the primary action button', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'https://example.com/video.mp4');
    await tester.pump();

    final buttonFinder = find.widgetWithText(FilledButton, 'Preview & Download');
    final button = tester.widget<FilledButton>(buttonFinder);
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Tapping Downloads nav destination switches screen', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });
}

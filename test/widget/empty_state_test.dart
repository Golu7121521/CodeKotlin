import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_video_downloader/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState displays icon, title, and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.download_rounded,
            title: 'No downloads yet',
            subtitle: 'Paste a video URL to get started.',
          ),
        ),
      ),
    );

    expect(find.text('No downloads yet'), findsOneWidget);
    expect(find.text('Paste a video URL to get started.'), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_video_downloader/services/download_service.dart';
import 'package:all_video_downloader/widgets/download_progress_card.dart';

void main() {
  testWidgets('DownloadProgressCard shows status text without progress', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DownloadProgressCard(statusText: 'Processing URL...'),
        ),
      ),
    );

    expect(find.text('Processing URL...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('DownloadProgressCard shows percentage and byte counts with progress', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DownloadProgressCard(
            statusText: 'Downloading...',
            progress: const DownloadProgress(
              downloadedBytes: 5 * 1024 * 1024,
              totalBytes: 10 * 1024 * 1024,
              bytesPerSecond: 1024 * 1024,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.textContaining('MB'), findsWidgets);
  });
}

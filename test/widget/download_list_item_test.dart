import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_video_downloader/models/download_item.dart';
import 'package:all_video_downloader/widgets/download_list_item.dart';

void main() {
  DownloadItem buildItem(DownloadStatus status) {
    return DownloadItem(
      id: 'id-1',
      url: 'https://example.com/source',
      downloadUrl: 'https://example.com/video.mp4',
      filename: 'sample.mp4',
      status: status,
    );
  }

  testWidgets('DownloadListItem shows Failed subtitle and delete action for failed status',
      (tester) async {
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DownloadListItem(
            item: buildItem(DownloadStatus.failed),
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    expect(find.text('Failed'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();
    expect(deleted, isTrue);
  });

  testWidgets('DownloadListItem shows play/share/delete actions for completed status',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DownloadListItem(
            item: buildItem(DownloadStatus.completed),
            onPlay: () {},
            onShare: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('DownloadListItem shows progress bar while downloading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DownloadListItem(item: buildItem(DownloadStatus.downloading)),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}

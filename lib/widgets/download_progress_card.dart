import 'package:flutter/material.dart';

import '../services/download_service.dart';
import '../utils/format_utils.dart';

class DownloadProgressCard extends StatelessWidget {
  const DownloadProgressCard({
    super.key,
    required this.statusText,
    this.progress,
  });

  final String statusText;
  final DownloadProgress? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = progress?.fraction ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AnimatedDownloadIcon(active: progress != null),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (progress != null)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      FormatUtils.formatPercent(fraction),
                      key: ValueKey(FormatUtils.formatPercent(fraction)),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 250),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: progress?.totalBytes != null ? value : null,
                  minHeight: 8,
                ),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${FormatUtils.formatBytes(progress!.downloadedBytes)} / '
                    '${FormatUtils.formatBytes(progress!.totalBytes)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    FormatUtils.formatSpeed(progress!.bytesPerSecond),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedDownloadIcon extends StatefulWidget {
  const _AnimatedDownloadIcon({required this.active});
  final bool active;

  @override
  State<_AnimatedDownloadIcon> createState() => _AnimatedDownloadIconState();
}

class _AnimatedDownloadIconState extends State<_AnimatedDownloadIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = widget.active ? (_controller.value * 4 - 2).abs() - 1 : 0.0;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: Icon(
        Icons.file_download_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

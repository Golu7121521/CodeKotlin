import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/downloads_provider.dart';
import '../providers/settings_provider.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../utils/format_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storageService = StorageService();
  final _downloadService = DownloadService();
  int _cacheSize = 0;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final cache = await _storageService.getAppCacheSize();
    String version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {
      version = '1.0.0';
    }
    if (mounted) {
      setState(() {
        _cacheSize = cache;
        _appVersion = version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionHeader('Appearance'),
          RadioListTile<AppThemeMode>(
            title: const Text('System default'),
            value: AppThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (v) => settingsProvider.updateThemeMode(v!),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Light'),
            value: AppThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (v) => settingsProvider.updateThemeMode(v!),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Dark'),
            value: AppThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (v) => settingsProvider.updateThemeMode(v!),
          ),
          const Divider(),
          _SectionHeader('Downloads'),
          SwitchListTile(
            title: const Text('Ask before download'),
            subtitle: const Text('Confirm before saving to permanent storage'),
            value: settings.askBeforeDownload,
            onChanged: settingsProvider.updateAskBeforeDownload,
          ),
          SwitchListTile(
            title: const Text('Auto cleanup temporary files'),
            subtitle: const Text('Remove preview files you don\'t download'),
            value: settings.autoCleanupTemp,
            onChanged: settingsProvider.updateAutoCleanupTemp,
          ),
          const Divider(),
          _SectionHeader('Player'),
          ListTile(
            title: const Text('Default playback speed'),
            subtitle: Text('${settings.defaultPlaybackSpeed}x'),
            trailing: DropdownButton<double>(
              value: settings.defaultPlaybackSpeed,
              items: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                  .map((s) => DropdownMenuItem(value: s, child: Text('${s}x')))
                  .toList(),
              onChanged: (v) {
                if (v != null) settingsProvider.updatePlaybackSpeed(v);
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Auto fullscreen'),
            value: settings.autoFullscreen,
            onChanged: settingsProvider.updateAutoFullscreen,
          ),
          SwitchListTile(
            title: const Text('Remember zoom level'),
            value: settings.rememberZoom,
            onChanged: settingsProvider.updateRememberZoom,
          ),
          SwitchListTile(
            title: const Text('Auto-hide controls'),
            value: settings.autoHideControls,
            onChanged: settingsProvider.updateAutoHideControls,
          ),
          const Divider(),
          _SectionHeader('Storage'),
          ListTile(
            title: const Text('Temporary cache size'),
            subtitle: Text(FormatUtils.formatBytes(_cacheSize)),
            trailing: TextButton(
              onPressed: () async {
                await _downloadService.clearTempCache();
                await _loadStats();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared')),
                  );
                }
              },
              child: const Text('Clear'),
            ),
          ),
          ListTile(
            title: const Text('Clear download history'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _confirmClearHistory(context),
          ),
          ListTile(
            title: const Text('Delete all downloaded videos'),
            titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.error),
            trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.error),
            onTap: () => _confirmDeleteAll(context),
          ),
          const Divider(),
          _SectionHeader('About'),
          ListTile(
            title: const Text('App version'),
            subtitle: Text(_appVersion.isEmpty ? 'Loading...' : _appVersion),
          ),
          ListTile(
            title: const Text('Privacy information'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Open-source licenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(context: context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear download history?'),
        content: const Text('This removes all history entries. Downloaded files on disk are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<DownloadsProvider>().clearHistory();
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all downloaded videos?'),
        content: const Text('This permanently deletes every downloaded video file. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final provider = context.read<DownloadsProvider>();
      for (final item in List.of(provider.all)) {
        await provider.deleteItem(item.id, deleteFile: true);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

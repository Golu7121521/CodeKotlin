import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../providers/theme_provider.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _sectionHeader(context, 'Theme'),
            _card(context, [
              _themeTile(context, themeProvider, 'Dark', ThemeMode.dark),
              _divider(context),
              _themeTile(context, themeProvider, 'Light', ThemeMode.light),
              _divider(context),
              _themeTile(context, themeProvider, 'System Default', ThemeMode.system),
            ]),
            _sectionHeader(context, 'Data'),
            _card(context, [
              ListTile(
                title: Text('Clear Recently Played',
                    style: TextStyle(color: context.colors.textPrimary)),
                onTap: () => _confirmClearRecent(context),
              ),
              _divider(context),
              ListTile(
                title: Text('Clear Image Cache', style: TextStyle(color: context.colors.textPrimary)),
                onTap: () async {
                  await DefaultCacheManager().emptyCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared')),
                  );
                },
              ),
            ]),
            _sectionHeader(context, 'About'),
            _card(context, [
              ListTile(
                title: Text('App Version', style: TextStyle(color: context.colors.textPrimary)),
                trailing: Text('1.0.0', style: TextStyle(color: context.colors.textSecondary)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          color: context.colors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(height: 1, color: context.colors.stroke);
  }

  Widget _themeTile(
    BuildContext context,
    ThemeProvider provider,
    String label,
    ThemeMode mode,
  ) {
    final isSelected = provider.themeMode == mode;
    return ListTile(
      title: Text(label, style: TextStyle(color: context.colors.textPrimary)),
      trailing: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppColors.accentViolet : context.colors.textTertiary,
      ),
      onTap: () => provider.setThemeMode(mode),
    );
  }

  void _confirmClearRecent(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Recently Played'),
        content: const Text('This will permanently clear your listening history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<LibraryProvider>().clearRecentlyPlayed();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/performance_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final performance = context.watch<PerformanceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.accentBrandMuted,
                  child: Icon(Icons.person_rounded, color: AppColors.accentBrand, size: 32),
                ),
                SizedBox(width: AppSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guest Viewer', style: AppTypography.titleLg),
                    Text('Free plan', style: AppTypography.bodySm),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xxl),
          const _SectionHeader('Accessibility & Performance'),
          SwitchListTile(
            title: const Text('Reduced Motion & Effects'),
            subtitle: const Text(
              'Disables blur/parallax effects and shortens animations for low-end devices or personal preference.',
            ),
            value: performance.userPreference == AppPerformanceModePref.reduced,
            onChanged: (value) => performance.setUserPreference(
              value ? AppPerformanceModePref.reduced : AppPerformanceModePref.auto,
            ),
          ),
          const Divider(height: AppSpacing.xxl),
          const _SectionHeader('About'),
          const ListTile(
            title: Text('App version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            title: Text('Content sourcing'),
            subtitle: Text(
              'Metadata provided by TMDB. Playback sources are configured directly by this app\'s operator \u2014 no third-party scraping is performed.',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSm.copyWith(color: AppColors.accentBrand),
      ),
    );
  }
}

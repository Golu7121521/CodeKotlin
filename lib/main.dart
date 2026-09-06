import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/downloads_provider.dart';
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  final downloadsProvider = DownloadsProvider();
  await downloadsProvider.loadFromDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: downloadsProvider),
      ],
      child: const AllVideoDownloaderApp(),
    ),
  );
}

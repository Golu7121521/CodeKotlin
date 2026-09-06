import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/player_provider.dart';
import 'providers/library_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SynesthesiaApp());
}

class SynesthesiaApp extends StatefulWidget {
  const SynesthesiaApp({super.key});

  @override
  State<SynesthesiaApp> createState() => _SynesthesiaAppState();
}

class _SynesthesiaAppState extends State<SynesthesiaApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.loadSavedTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()..loadAll()),
        ChangeNotifierProvider.value(value: _themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Synesthesia',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}

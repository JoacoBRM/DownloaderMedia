import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/app_localizations.dart';
import 'features/home/home_screen.dart';
import 'features/downloads/downloads_screen.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/downloads/providers/download_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'shared/widgets/window_title_bar.dart';
import 'shared/widgets/sidebar_nav.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'DownloaderMedia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: settings.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;
  bool _needsSetup = true;
  bool _checkingBinaries = true;

  @override
  void initState() {
    super.initState();
    _checkBinaries();
  }

  Future<void> _checkBinaries() async {
    final status = await ref.read(binaryManagerProvider).checkStatus();
    setState(() {
      _needsSetup = !status.allReady;
      _checkingBinaries = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingBinaries) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_needsSetup) {
      return SetupScreen(
        onComplete: () {
          setState(() => _needsSetup = false);
        },
      );
    }

    final screens = [
      const HomeScreen(),
      const DownloadsScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          const WindowTitleBar(),
          Expanded(
            child: Row(
              children: [
                SidebarNav(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: screens[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

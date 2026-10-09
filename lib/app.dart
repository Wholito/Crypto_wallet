import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/mono_clock.dart';
import 'features/authentication/presentation/providers/auth_provider.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'shared/widgets/app_logo.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  int? _pausedAtMs;
  bool _privacyCover = false;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = ref.read(appRouterProvider);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _lock() {
    final nav = rootNavigatorKey.currentState;
    while (nav?.canPop() ?? false) {
      nav?.pop();
    }
    ref.read(sessionProvider.notifier).lock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (!_privacyCover) setState(() => _privacyCover = true);
    }
    if (state == AppLifecycleState.paused) {
      _pausedAtMs = MonoClock.nowMs();
    } else if (state == AppLifecycleState.resumed) {
      if (_privacyCover) setState(() => _privacyCover = false);
      final pausedAt = _pausedAtMs;
      _pausedAtMs = null;
      if (pausedAt != null &&
          MonoClock.nowMs() - pausedAt >=
              AppConstants.autoLockSeconds * 1000) {
        _lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(settingsProvider.select((s) => s.theme));
    return MaterialApp.router(
      title: 'Crypto Wallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeOutCubic,
      routerConfig: _router,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          ?child,
          if (_privacyCover)
            const ColoredBox(
              color: AppTheme.black,
              child: Center(
                child: AppLogo(size: 72),
              ),
            ),
        ],
      ),
    );
  }
}

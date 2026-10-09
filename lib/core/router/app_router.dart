import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assets/domain/entities/asset.dart';
import '../../features/assets/presentation/pages/asset_details_page.dart';
import '../../features/assets/presentation/pages/assets_page.dart';
import '../../features/authentication/presentation/pages/pin_page.dart';
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/onboarding/presentation/pages/create_wallet_page.dart';
import '../../features/onboarding/presentation/pages/restore_wallet_page.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/receive/presentation/pages/receive_page.dart';
import '../../features/send/presentation/pages/send_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transactions/presentation/pages/transaction_details_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/error_view.dart';
import 'app_routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final location = state.matchedLocation;
      final status = session.value;
      if (status == null) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }
      switch (status) {
        case SessionStatus.noWallet:
          return location.startsWith(AppRoutes.onboardingPrefix)
              ? null
              : AppRoutes.welcome;
        case SessionStatus.locked:
          return location == AppRoutes.pin ? null : AppRoutes.pin;
        case SessionStatus.unlocked:
          return location.startsWith(AppRoutes.walletPrefix)
              ? null
              : AppRoutes.home;
      }
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const _SplashPage()),
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomePage()),
      GoRoute(
        path: AppRoutes.createWallet,
        builder: (_, _) => const CreateWalletPage(),
      ),
      GoRoute(
        path: AppRoutes.restoreWallet,
        builder: (_, _) => const RestoreWalletPage(),
      ),
      GoRoute(path: AppRoutes.pin, builder: (_, _) => const PinPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const WalletPage()),
      GoRoute(path: AppRoutes.assets, builder: (_, _) => const AssetsPage()),
      GoRoute(
        path: AppRoutes.assetDetails,
        builder: (_, state) {
          final asset = state.extra;
          return asset is Asset
              ? AssetDetailsPage(asset: asset)
              : const AssetsPage();
        },
      ),
      GoRoute(
        path: AppRoutes.send,
        builder: (_, state) {
          final extra = state.extra;
          return SendPage(initialAsset: extra is Asset ? extra : null);
        },
      ),
      GoRoute(path: AppRoutes.receive, builder: (_, _) => const ReceivePage()),
      GoRoute(
        path: AppRoutes.transactions,
        builder: (_, _) => const TransactionsPage(),
      ),
      GoRoute(
        path: AppRoutes.transactionDetails,
        builder: (_, state) => TransactionDetailsPage(
          hash: state.uri.queryParameters['hash'] ?? '',
        ),
      ),
      GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _SplashPage extends ConsumerWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      body: session.hasError
          ? ErrorView(
              error: session.error!,
              onRetry: () => ref.invalidate(sessionProvider),
            )
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(size: 72, showGlow: true),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                ],
              ),
            ),
    );
  }
}

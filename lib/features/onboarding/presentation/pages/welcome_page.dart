import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/fade_slide_in.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const FadeSlideIn(
                child: AppLogo(size: 120, showGlow: true),
              ),
              const SizedBox(height: 32),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  'Crypto Wallet',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: Text(
                  'Your keys never leave this device.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(flex: 3),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: FilledButton(
                  key: const Key('create_wallet_button'),
                  onPressed: () => context.go(AppRoutes.createWallet),
                  child: const Text('Create new wallet'),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: OutlinedButton(
                  key: const Key('restore_wallet_button'),
                  onPressed: () => context.go(AppRoutes.restoreWallet),
                  child: const Text('I already have a wallet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

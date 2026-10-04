import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../market/presentation/providers/market_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/address_card.dart';
import '../widgets/asset_list.dart';
import '../widgets/balance_card.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(walletAddressProvider);
    final settings = ref.watch(settingsProvider);
    final assets = ref.watch(pricedAssetsProvider);

    Future<void> refresh() async {
      await ref.read(assetsProvider.notifier).refresh();
      ref.read(transactionsProvider.notifier).refresh();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            key: const Key('settings_button'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: address == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  BalanceCard(
                    network: settings.network,
                    asset: assets.value?.firstOrNull,
                    total: ref.watch(portfolioValueProvider),
                    currency: settings.currency,
                  ),
                  if (assets.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage(assets.error!),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  if (assets.isLoading && !assets.hasValue)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  const SizedBox(height: 16),
                  AddressCard(address: address),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Action(
                        key: const Key('send_action'),
                        icon: Icons.arrow_upward,
                        label: 'Send',
                        onTap: () => context.push(AppRoutes.send),
                      ),
                      _Action(
                        key: const Key('receive_action'),
                        icon: Icons.arrow_downward,
                        label: 'Receive',
                        onTap: () => context.push(AppRoutes.receive),
                      ),
                      _Action(
                        key: const Key('history_action'),
                        icon: Icons.history,
                        label: 'History',
                        onTap: () => context.push(AppRoutes.transactions),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Assets',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (assets.hasValue)
                    AssetList(assets: assets.value!, currency: settings.currency),
                ],
              ),
            ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primaryContainer,
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

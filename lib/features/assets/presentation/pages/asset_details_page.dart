import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/asset_icon.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/asset.dart';

class AssetDetailsPage extends ConsumerWidget {
  const AssetDetailsPage({required this.asset, super.key});

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(settingsProvider.select((s) => s.currency));
    return Scaffold(
      appBar: AppBar(title: Text(asset.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: AssetIcon(symbol: asset.symbol, size: 72)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${asset.formattedBalance} ${asset.symbol}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Balance'),
                  trailing: Text('${asset.formattedBalance} ${asset.symbol}'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Type'),
                  trailing:
                      Text(asset.contractAddress == null ? 'Native' : 'Token'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Decimals'),
                  trailing: Text('${asset.decimals}'),
                ),
                if (asset.contractAddress != null) ...[
                  const Divider(),
                  ListTile(
                    title: const Text('Contract'),
                    subtitle: SelectableText(asset.contractAddress!),
                  ),
                ],
                if (asset.price != null) ...[
                  const Divider(),
                  ListTile(
                    title: const Text('Price'),
                    trailing: Text(Formatters.fiat(asset.price!, currency)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      context.push(AppRoutes.send, extra: asset),
                  child: const Text('Send'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.receive),
                  child: const Text('Receive'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

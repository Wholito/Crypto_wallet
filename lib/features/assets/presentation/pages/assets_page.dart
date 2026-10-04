import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_view.dart';
import '../../../market/presentation/providers/market_provider.dart';
import '../../../wallet/presentation/widgets/asset_list.dart';
import '../providers/assets_provider.dart';

class AssetsPage extends ConsumerWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(pricedAssetsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Assets')),
      body: assets.when(
        skipError: true,
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.read(assetsProvider.notifier).refresh(),
          child: ListView(children: [AssetList(assets: list)]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(assetsProvider),
        ),
      ),
    );
  }
}

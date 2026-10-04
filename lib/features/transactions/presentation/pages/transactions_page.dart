import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/error_view.dart';
import '../providers/transactions_provider.dart';
import '../widgets/transaction_tile.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(transactionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: txs.when(
        skipError: true,
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.read(transactionsProvider.notifier).refresh(),
          child: list.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        AppConstants.etherscanApiKey.isEmpty &&
                                AppConstants.backendUrl.isEmpty
                            ? 'No transactions sent from this device yet.'
                            : 'No transactions yet.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => Card(
                    clipBehavior: Clip.antiAlias,
                    child: TransactionTile(
                      key: Key('tx_${list[i].hash}'),
                      transaction: list[i],
                      onTap: () => context.push(
                        '${AppRoutes.transactionDetails}?hash=${list[i].hash}',
                      ),
                    ),
                  ),
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(transactionsProvider),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/units.dart';
import '../../../../shared/widgets/copy_button.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../providers/transactions_provider.dart';
import '../widgets/transaction_tile.dart';

class TransactionDetailsPage extends ConsumerWidget {
  const TransactionDetailsPage({required this.hash, super.key});

  final String hash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(transactionsProvider).value ?? const [];
    final network = ref.watch(currentNetworkProvider);
    final tx = txs
        .where((t) => t.hash.toLowerCase() == hash.toLowerCase())
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction')),
      body: tx == null
          ? const Center(child: Text('Transaction not found.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _row('Status', tx.status.label,
                    color: tx.status.color(context), key: 'detail_status'),
                _row(
                  'Amount',
                  tx.isContractCall
                      ? 'Contract call'
                      : '${Units.format(tx.amount, tx.decimals)} ${tx.asset}',
                ),
                if (tx.type == TxType.sent)
                  _row(
                    'Fee',
                    '${Units.format(tx.fee, network.nativeCurrency.decimals)} ${network.nativeCurrency.symbol}',
                  )
                else
                  _row('Fee', 'Paid by sender'),
                _row(
                  'Date',
                  tx.status == TxStatus.pending &&
                          tx.timestamp.millisecondsSinceEpoch == 0
                      ? 'Awaiting confirmation'
                      : Formatters.dateTime(tx.timestamp),
                ),
                _copyRow(context, 'From', tx.from),
                _copyRow(context, 'To', tx.to),
                _copyRow(context, 'Hash', tx.hash),
                _copyRow(context, 'Explorer', network.txUrl(tx.hash)),
              ],
            ),
    );
  }

  Widget _row(String title, String value, {Color? color, String? key}) =>
      ListTile(
        title: Text(title),
        trailing: Text(value, key: key == null ? null : Key(key), style: TextStyle(color: color)),
      );

  Widget _copyRow(BuildContext context, String title, String value) => ListTile(
        title: Text(title),
        subtitle: Text(value),
        trailing: CopyIconButton(value: value, message: '$title copied'),
      );
}

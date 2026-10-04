import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/units.dart';
import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/wallet_transaction.dart';

extension TxStatusX on TxStatus {
  String get label => switch (this) {
        TxStatus.pending => 'Pending',
        TxStatus.confirmed => 'Confirmed',
        TxStatus.failed => 'Failed',
        TxStatus.dropped => 'Dropped',
      };

  Color color(BuildContext context) => switch (this) {
        TxStatus.pending => Colors.orange,
        TxStatus.confirmed => Colors.green,
        TxStatus.failed => Theme.of(context).colorScheme.error,
        TxStatus.dropped => Theme.of(context).colorScheme.outline,
      };
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, this.onTap, super.key});

  final WalletTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tx = transaction;
    final sent = tx.type == TxType.sent;
    final amount = tx.isContractCall
        ? 'Contract call'
        : '${sent ? '-' : '+'}${Units.format(tx.amount, tx.decimals, maxFraction: 6)} ${tx.asset}';
    final statusColor = tx.status.color(context);
    final iconColor = tx.isContractCall
        ? theme.colorScheme.primary
        : sent
            ? Colors.redAccent
            : Colors.green;
    final dateLabel = tx.status == TxStatus.pending &&
            tx.timestamp.millisecondsSinceEpoch == 0
        ? 'Awaiting confirmation'
        : Formatters.dateTime(tx.timestamp);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withValues(alpha: 0.12),
        ),
        child: Icon(
          tx.isContractCall
              ? Icons.code_rounded
              : sent
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
          color: iconColor,
        ),
      ),
      title: Text(amount, style: theme.textTheme.titleMedium),
      subtitle: Text(
        '${sent ? 'To' : 'From'} ${(sent ? tx.to : tx.from).shortAddress}\n'
        '$dateLabel',
      ),
      isThreeLine: true,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          tx.status.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

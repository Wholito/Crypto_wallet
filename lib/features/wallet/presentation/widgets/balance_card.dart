import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/network.dart';
import '../../../assets/domain/entities/asset.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.network,
    required this.asset,
    this.total,
    this.currency = 'USD',
    super.key,
  });

  final Network network;
  final Asset? asset;
  final double? total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = total ?? asset?.fiatValue;
    final onGradient = Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, const Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  network.name,
                  style: theme.textTheme.labelLarge?.copyWith(color: onGradient),
                ),
              ),
              if (network.isTestnet) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Testnet',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Balance',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onGradient.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            asset == null ? '—' : '${asset!.formattedBalance} ${asset!.symbol}',
            key: const Key('balance_text'),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: onGradient,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (value != null) ...[
            const SizedBox(height: 4),
            Text(
              Formatters.fiat(value, currency),
              style: theme.textTheme.titleMedium?.copyWith(
                color: onGradient.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (network.isTestnet) ...[
            const SizedBox(height: 12),
            Text(
              'Testnet coins have no value',
              style: theme.textTheme.bodySmall?.copyWith(
                color: onGradient.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

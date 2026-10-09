import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final value = total ?? asset?.fiatValue;
    final onGradient = isDark ? AppTheme.yellow : AppTheme.black;
    final muted = onGradient.withValues(alpha: 0.72);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1A1A1A), Color(0xFF0A0A0A), Color(0xFF2A2200)]
              : const [Color(0xFFFFF7D1), Color(0xFFF5C400), Color(0xFFE0B000)],
        ),
        border: Border.all(
          color: isDark
              ? AppTheme.yellow.withValues(alpha: 0.35)
              : AppTheme.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.yellow.withValues(alpha: isDark ? 0.18 : 0.28),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: onGradient.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: onGradient.withValues(alpha: 0.2)),
                ),
                child: Text(
                  network.name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: onGradient,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (network.isTestnet) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Testnet',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.yellow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Balance',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 4),
          Text(
            asset == null ? '—' : '${asset!.formattedBalance} ${asset!.symbol}',
            key: const Key('balance_text'),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: onGradient,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (value != null) ...[
            const SizedBox(height: 4),
            Text(
              Formatters.fiat(value, currency),
              style: theme.textTheme.titleMedium?.copyWith(color: muted),
            ),
          ],
          if (network.isTestnet) ...[
            const SizedBox(height: 12),
            Text(
              'Testnet coins have no value',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/asset_icon.dart';
import '../../../assets/domain/entities/asset.dart';

class AssetList extends StatelessWidget {
  const AssetList({required this.assets, this.currency = 'USD', super.key});

  final List<Asset> assets;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < assets.length; i++) ...[
            if (i > 0) const Divider(indent: 72),
            _tile(context, theme, assets[i]),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, ThemeData theme, Asset asset) {
    final fiat = asset.fiatValue;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: AssetIcon(symbol: asset.symbol),
      title: Text(asset.name, style: theme.textTheme.titleMedium),
      subtitle: Text(asset.symbol),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${asset.formattedBalance} ${asset.symbol}',
            style: theme.textTheme.titleSmall,
          ),
          if (fiat != null)
            Text(
              Formatters.fiat(fiat, currency),
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      onTap: () => context.push(AppRoutes.assetDetails, extra: asset),
    );
  }
}

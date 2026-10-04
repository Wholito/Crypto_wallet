import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/extensions/string_extensions.dart';
import '../../../../shared/widgets/error_view.dart';

class AddressCard extends StatelessWidget {
  const AddressCard({required this.address, super.key});

  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Address', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    address.shortAddress,
                    key: const Key('address_text'),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: address));
                if (context.mounted) showMessage(context, 'Address copied');
              },
            ),
          ],
        ),
      ),
    );
  }
}

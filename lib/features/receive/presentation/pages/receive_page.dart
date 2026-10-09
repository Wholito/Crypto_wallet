import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../shared/widgets/copy_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/receive_provider.dart';

class ReceivePage extends ConsumerWidget {
  const ReceivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(receiveAddressProvider);
    final network = ref.watch(currentNetworkProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: address.when(
        data: (value) {
          final theme = Theme.of(context);
          final symbols = [
            network.nativeCurrency.symbol,
            ...network.tokens.map((t) => t.symbol),
          ].join(', ');
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    key: const Key('qr_code'),
                    data: ref.read(generateQrCodeProvider)(value),
                    size: 220,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Chip(
                  label: Text(network.name),
                  side: BorderSide.none,
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    value,
                    key: const Key('receive_address'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CopyFilledButton(value: value),
              const SizedBox(height: 16),
              Text(
                'Send only $symbols on ${network.name} to this address.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/units.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../assets/domain/entities/asset.dart';
import '../../../authentication/presentation/widgets/auth_dialog.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/entities/wallet_transaction.dart';
import '../providers/send_provider.dart';

class SendPage extends ConsumerStatefulWidget {
  const SendPage({this.initialAsset, super.key});

  final Asset? initialAsset;

  @override
  ConsumerState<SendPage> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendPage> {
  final _formKey = GlobalKey<FormState>();
  final _to = TextEditingController();
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final asset = widget.initialAsset;
      if (asset != null) {
        ref.read(sendProvider.notifier).setInitial(
              symbol: asset.symbol,
              decimals: asset.decimals,
              contractAddress: asset.contractAddress,
            );
      } else {
        ref.read(sendProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _to.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _fillMax() async {
    if (_to.text.trim().isEmpty) {
      showMessage(context, 'Enter recipient address first.');
      return;
    }
    final value = await ref.read(sendProvider.notifier).maxAmount(_to.text);
    if (!mounted) return;
    if (value == null) {
      showMessage(context, 'Unable to calculate maximum amount.');
      return;
    }
    _amount.text = value;
  }

  Future<void> _review() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(sendProvider.notifier);
    await notifier.prepare(_to.text, _amount.text);
    if (!mounted) return;
    final state = ref.read(sendProvider);
    if (state.status != SendStatus.ready) {
      showMessage(context, state.error ?? 'Unable to prepare transaction.');
      return;
    }
    final network = ref.read(currentNetworkProvider);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ConfirmSheet(
        request: state.request!,
        feeSymbol: network.nativeCurrency.symbol,
        feeDecimals: network.nativeCurrency.decimals,
      ),
    );
    if (confirmed != true || !mounted) return;
    final token =
        await confirmAuth(context, ref, reason: 'Confirm transaction');
    if (token == null || !mounted) return;
    await notifier.confirm(token);
    if (!mounted) return;
    final result = ref.read(sendProvider);
    if (result.status == SendStatus.sent) {
      context.pushReplacement(
        '${AppRoutes.transactionDetails}?hash=${result.transaction!.hash}',
      );
    } else {
      showMessage(context, result.error ?? 'Transaction failed.');
    }
  }

  List<SendAssetOption> _options() {
    final network = ref.read(currentNetworkProvider);
    return [
      SendAssetOption(
        symbol: network.nativeCurrency.symbol,
        decimals: network.nativeCurrency.decimals,
      ),
      for (final token in network.tokens)
        SendAssetOption(
          symbol: token.symbol,
          decimals: token.decimals,
          contractAddress: token.contractAddress,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(sendProvider.select((s) => s.status));
    final selected = ref.watch(sendProvider.select((s) => s.selected));
    final network = ref.watch(currentNetworkProvider);
    final busy = status == SendStatus.preparing || status == SendStatus.sending;
    final options = _options();
    final symbol = selected?.symbol ?? network.nativeCurrency.symbol;
    return Scaffold(
      appBar: AppBar(title: Text('Send $symbol')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (options.length > 1) ...[
                Text('Asset', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in options)
                      ChoiceChip(
                        key: Key('asset_${option.symbol}'),
                        label: Text(option.symbol),
                        selected: selected?.symbol == option.symbol &&
                            selected?.contractAddress == option.contractAddress,
                        onSelected: busy
                            ? null
                            : (_) {
                                ref
                                    .read(sendProvider.notifier)
                                    .selectAsset(option);
                                _amount.clear();
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: const Key('recipient_field'),
                controller: _to,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Recipient address',
                  hintText: '0x...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter recipient address'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('amount_field'),
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  suffixText: symbol,
                  suffixIcon: TextButton(
                    key: const Key('max_button'),
                    onPressed: busy ? null : _fillMax,
                    child: const Text('Max'),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter amount' : null,
              ),
              if (selected?.isToken == true) ...[
                const SizedBox(height: 12),
                Text(
                  'Network fee is paid in ${network.nativeCurrency.symbol}.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('review_button'),
                onPressed: busy ? null : _review,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.request,
    required this.feeSymbol,
    required this.feeDecimals,
  });

  final SendRequest request;
  final String feeSymbol;
  final int feeDecimals;

  @override
  Widget build(BuildContext context) {
    final fee = request.estimate.fee;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (request.warning != null) ...[
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(request.warning!),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _line('Asset', request.asset),
            _line('To', request.to),
            _line(
              'Amount',
              '${Units.format(request.amount, request.decimals)} ${request.asset}',
            ),
            _line(
              'Network fee',
              '${Units.format(fee, feeDecimals)} $feeSymbol',
            ),
            if (!request.isToken)
              _line(
                'Total',
                '${Units.format(request.amount + fee, request.decimals)} ${request.asset}',
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('confirm_send'),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 100, child: Text(label)),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

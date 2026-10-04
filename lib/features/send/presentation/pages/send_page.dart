import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/units.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../authentication/presentation/widgets/auth_dialog.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/domain/entities/wallet_transaction.dart';
import '../providers/send_provider.dart';

class SendPage extends ConsumerStatefulWidget {
  const SendPage({super.key});

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
      if (mounted) ref.read(sendProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _to.dispose();
    _amount.dispose();
    super.dispose();
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
        symbol: network.nativeCurrency.symbol,
        decimals: network.nativeCurrency.decimals,
      ),
    );
    if (confirmed != true || !mounted) return;
    final authorized = await confirmAuth(context, ref, reason: 'Confirm transaction');
    if (!authorized || !mounted) return;
    await notifier.confirm();
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

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(sendProvider.select((s) => s.status));
    final network = ref.watch(currentNetworkProvider);
    final busy = status == SendStatus.preparing || status == SendStatus.sending;
    return Scaffold(
      appBar: AppBar(title: Text('Send ${network.nativeCurrency.symbol}')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('recipient_field'),
                controller: _to,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Recipient address',
                  hintText: '0x...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter recipient address'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('amount_field'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  suffixText: network.nativeCurrency.symbol,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter amount' : null,
              ),
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
    required this.symbol,
    required this.decimals,
  });

  final SendRequest request;
  final String symbol;
  final int decimals;

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
            Text('Confirm transaction',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _line('To', request.to),
            _line('Amount', '${Units.format(request.amount, decimals)} $symbol'),
            _line('Network fee', '${Units.format(fee, decimals)} $symbol'),
            _line('Total',
                '${Units.format(request.amount + fee, decimals)} $symbol'),
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

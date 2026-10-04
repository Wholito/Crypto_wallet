import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/pin_setup.dart';

class RestoreWalletPage extends ConsumerStatefulWidget {
  const RestoreWalletPage({super.key});

  @override
  ConsumerState<RestoreWalletPage> createState() => _RestoreWalletPageState();
}

class _RestoreWalletPageState extends ConsumerState<RestoreWalletPage> {
  final _controller = TextEditingController();
  String _mnemonic = '';
  bool _pinStep = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    final text = _controller.text;
    if (!ref.read(walletRepositoryProvider).validateMnemonic(text)) {
      setState(() => _error = 'Invalid seed phrase.');
      return;
    }
    setState(() {
      _mnemonic = text;
      _pinStep = true;
      _error = null;
    });
  }

  Future<void> _restore(String pin) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(onboardingServiceProvider).restoreWallet(_mnemonic, pin);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore wallet'),
        leading: BackButton(onPressed: () {
          if (_pinStep) {
            setState(() => _pinStep = false);
          } else {
            context.go(AppRoutes.welcome);
          }
        }),
      ),
      body: SafeArea(
        child: _pinStep
            ? PinSetup(onPinSet: _restore, busy: _busy, error: _error)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Enter your 12 or 24 word seed phrase.'),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('mnemonic_field'),
                    controller: _controller,
                    minLines: 3,
                    maxLines: 5,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('restore_continue'),
                    onPressed: _next,
                    child: const Text('Continue'),
                  ),
                ],
              ),
      ),
    );
  }
}

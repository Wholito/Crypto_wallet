import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/pin_pad.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';

class PinPage extends ConsumerStatefulWidget {
  const PinPage({super.key});

  @override
  ConsumerState<PinPage> createState() => _PinPageState();
}

class _PinPageState extends ConsumerState<PinPage> {
  String? _error;
  bool _busy = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBiometric());
  }

  Future<void> _initBiometric() async {
    final enabled = await ref.read(authRepositoryProvider).isBiometricEnabled();
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
    if (enabled) await _biometric();
  }

  Future<void> _biometric() async {
    await ref.read(sessionProvider.notifier).unlockWithBiometrics();
  }

  Future<void> _unlock(String pin) async {
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).unlockWithPin(pin);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _busy = false;
        });
      }
    }
  }

  Future<void> _resetWallet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset wallet?'),
        content: const Text(
          'The wallet will be removed from this device. '
          'You can restore it later with your seed phrase. '
          'Without the seed phrase the funds cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm_reset_wallet'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(onboardingServiceProvider).resetWallet();
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                PinPad(
                  title: 'Enter PIN',
                  error: _error,
                  enabled: !_busy,
                  onCompleted: _unlock,
                  bottomLeft: _biometricEnabled
                      ? IconButton(
                          key: const Key('biometric_button'),
                          onPressed: _biometric,
                          icon: const Icon(Icons.fingerprint),
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                TextButton(
                  key: const Key('forgot_pin_button'),
                  onPressed: _busy ? null : _resetWallet,
                  child: const Text('Forgot PIN? Reset wallet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

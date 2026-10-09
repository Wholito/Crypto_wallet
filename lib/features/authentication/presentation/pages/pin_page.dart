import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/fade_slide_in.dart';
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
    try {
      final ok =
          await ref.read(sessionProvider.notifier).unlockWithBiometrics();
      if (!ok && mounted) {
        setState(() => _error = 'Biometric unlock failed. Enter your PIN.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    }
  }

  Future<void> _unlock(String pin) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    await Future<void>.delayed(Duration.zero);
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
                const FadeSlideIn(child: AppLogo(size: 84, showGlow: true)),
                const SizedBox(height: 20),
                if (_busy) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Unlocking…',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: PinPad(
                    title: 'Enter PIN',
                    error: _error,
                    enabled: !_busy,
                    onCompleted: _unlock,
                    bottomLeft: _biometricEnabled
                        ? IconButton(
                            key: const Key('biometric_button'),
                            onPressed: _biometric,
                            icon: const Icon(Icons.fingerprint_rounded),
                          )
                        : null,
                  ),
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

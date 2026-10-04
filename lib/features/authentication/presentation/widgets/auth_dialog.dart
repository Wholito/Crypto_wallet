import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/pin_pad.dart';
import '../providers/auth_provider.dart';

Future<bool> confirmAuth(BuildContext context, WidgetRef ref,
    {String reason = 'Confirm operation'}) async {
  final biometric = await ref.read(authenticateBiometricProvider)(reason);
  if (biometric) return true;
  if (!context.mounted) return false;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PinDialog(reason: reason),
  );
  return result ?? false;
}

class _PinDialog extends ConsumerStatefulWidget {
  const _PinDialog({required this.reason});

  final String reason;

  @override
  ConsumerState<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<_PinDialog> {
  String? _error;
  bool _busy = false;

  Future<void> _verify(String pin) async {
    setState(() => _busy = true);
    try {
      await ref.read(verifyPinProvider)(pin);
      if (mounted) Navigator.of(context).pop(true);
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
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PinPad(
                title: widget.reason,
                error: _error,
                enabled: !_busy,
                onCompleted: _verify,
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

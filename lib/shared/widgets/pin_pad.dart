import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class PinPad extends StatefulWidget {
  const PinPad({
    required this.title,
    required this.onCompleted,
    this.error,
    this.enabled = true,
    this.bottomLeft,
    super.key,
  });

  final String title;
  final ValueChanged<String> onCompleted;
  final String? error;
  final bool enabled;
  final Widget? bottomLeft;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _add(String digit) {
    if (!widget.enabled || _pin.length >= AppConstants.pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length == AppConstants.pinLength) {
      final value = _pin;
      setState(() => _pin = '');
      widget.onCompleted(value);
    }
  }

  void _remove() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(AppConstants.pinLength, (i) {
            final filled = i < _pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? theme.colorScheme.primary : Colors.transparent,
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 24,
          child: widget.error == null
              ? null
              : Text(
                  widget.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
        ),
        const SizedBox(height: 16),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) _key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 80, height: 72, child: widget.bottomLeft),
            _key('0'),
            SizedBox(
              width: 80,
              height: 72,
              child: IconButton(
                key: const Key('pin_backspace'),
                onPressed: _remove,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(String digit) => SizedBox(
        width: 80,
        height: 72,
        child: Center(
          child: SizedBox(
            width: 64,
            height: 64,
            child: TextButton(
              key: Key('pin_$digit'),
              style: TextButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onPressed: () => _add(digit),
              child: Text(
                digit,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        ),
      );
}

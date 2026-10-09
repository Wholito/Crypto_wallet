import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'error_view.dart';

class CopyIconButton extends StatefulWidget {
  const CopyIconButton({
    required this.value,
    this.message = 'Copied',
    this.icon = Icons.content_copy_rounded,
    this.iconSize = 20,
    this.filled = false,
    super.key,
  });

  final String value;
  final String message;
  final IconData icon;
  final double iconSize;
  final bool filled;

  @override
  State<CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<CopyIconButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    showMessage(context, widget.message);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Icon(
        _copied ? Icons.check_rounded : widget.icon,
        key: ValueKey(_copied),
        size: widget.iconSize,
        color: _copied ? scheme.primary : null,
      ),
    );
    if (widget.filled) {
      return IconButton.filledTonal(
        onPressed: _copied ? null : _copy,
        icon: child,
      );
    }
    return IconButton(
      onPressed: _copied ? null : _copy,
      icon: child,
    );
  }
}

class CopyFilledButton extends StatefulWidget {
  const CopyFilledButton({
    required this.value,
    this.label = 'Copy address',
    this.message = 'Address copied',
    super.key,
  });

  final String value;
  final String label;
  final String message;

  @override
  State<CopyFilledButton> createState() => _CopyFilledButtonState();
}

class _CopyFilledButtonState extends State<CopyFilledButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    showMessage(context, widget.message);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: FilledButton.icon(
        key: ValueKey(_copied),
        onPressed: _copied ? null : _copy,
        icon: Icon(_copied ? Icons.check_rounded : Icons.content_copy_rounded),
        label: Text(_copied ? 'Copied' : widget.label),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../shared/widgets/pin_pad.dart';

class PinSetup extends StatefulWidget {
  const PinSetup({required this.onPinSet, this.busy = false, this.error, super.key});

  final ValueChanged<String> onPinSet;
  final bool busy;
  final String? error;

  @override
  State<PinSetup> createState() => _PinSetupState();
}

class _PinSetupState extends State<PinSetup> {
  String? _first;
  String? _mismatch;

  @override
  void didUpdateWidget(covariant PinSetup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != null && widget.error != oldWidget.error) {
      _first = null;
      _mismatch = null;
    }
  }

  void _onCompleted(String pin) {
    if (_first == null) {
      setState(() {
        _first = pin;
        _mismatch = null;
      });
    } else if (_first == pin) {
      widget.onPinSet(pin);
    } else {
      setState(() {
        _first = null;
        _mismatch = 'PINs do not match. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: PinPad(
          title: _first == null ? 'Create a 6-digit PIN' : 'Repeat PIN',
          error: widget.error ?? _mismatch,
          enabled: !widget.busy,
          onCompleted: _onCompleted,
        ),
      ),
    );
  }
}

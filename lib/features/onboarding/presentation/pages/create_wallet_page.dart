import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/pin_setup.dart';

class CreateWalletPage extends ConsumerStatefulWidget {
  const CreateWalletPage({super.key});

  @override
  ConsumerState<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends ConsumerState<CreateWalletPage> {
  late final List<String> _words;
  late final List<int> _quiz;
  final _controllers = <TextEditingController>[];
  int _step = 0;
  bool _saved = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _words = ref.read(generateMnemonicProvider)().split(' ');
    final indexes = List<int>.generate(_words.length, (i) => i)
      ..shuffle(Random.secure());
    _quiz = indexes.take(3).toList()..sort();
    for (var i = 0; i < _quiz.length; i++) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _verify() {
    final ok = List.generate(_quiz.length, (i) {
      return _controllers[i].text.trim().toLowerCase() == _words[_quiz[i]];
    }).every((e) => e);
    if (ok) {
      setState(() {
        _step = 2;
        _error = null;
      });
    } else {
      setState(() => _error = 'Words do not match. Check your backup.');
    }
  }

  Future<void> _create(String pin) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(onboardingServiceProvider).createWallet(_words.join(' '), pin);
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
        title: const Text('Create wallet'),
        leading: _step == 2
            ? null
            : BackButton(onPressed: () {
                if (_step == 1) {
                  setState(() => _step = 0);
                } else {
                  context.go(AppRoutes.welcome);
                }
              }),
      ),
      body: SafeArea(
        child: switch (_step) {
          0 => _backupStep(context),
          1 => _verifyStep(context),
          _ => PinSetup(onPinSet: _create, busy: _busy, error: _error),
        },
      ),
    );
  }

  Widget _backupStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Write down these 12 words in order and keep them offline. '
                    'Anyone with this phrase controls your funds. It is shown only once.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.2,
          children: [
            for (var i = 0; i < _words.length; i++)
              Container(
                key: Key('seed_word_$i'),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${i + 1}. ${_words[i]}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ),        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            final mnemonic = _words.join(' ');
            await Clipboard.setData(ClipboardData(text: mnemonic));
            Future.delayed(const Duration(seconds: 30), () async {
              final current = await Clipboard.getData('text/plain');
              if (current?.text == mnemonic) {
                await Clipboard.setData(const ClipboardData(text: ''));
              }
            });
            if (context.mounted) {
              showMessage(context, 'Copied. Clipboard will be cleared in 30 s.');
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
        CheckboxListTile(
          key: const Key('backup_checkbox'),
          value: _saved,
          onChanged: (v) => setState(() => _saved = v ?? false),
          title: const Text('I have saved my seed phrase'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        FilledButton(
          key: const Key('backup_continue'),
          onPressed: _saved ? () => setState(() => _step = 1) : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _verifyStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Confirm your backup by entering the requested words.',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        for (var i = 0; i < _quiz.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              key: Key('quiz_$i'),
              controller: _controllers[i],
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Word #${_quiz[i] + 1}',
              ),
            ),
          ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('verify_continue'),
          onPressed: _verify,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

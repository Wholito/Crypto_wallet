import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/networks.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../authentication/presentation/widgets/auth_dialog.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/security_provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final biometricAvailable = ref.watch(biometricAvailableProvider).value ?? false;
    final biometricEnabled = ref.watch(biometricEnabledProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('Network', [
            for (final network in Networks.all)
              ListTile(
                key: Key('network_${network.id}'),
                title: Text(network.name),
                subtitle: Text('Chain ID ${network.chainId}'),
                trailing: Icon(
                  settings.network.id == network.id
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: settings.network.id == network.id
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                onTap: () =>
                    ref.read(settingsProvider.notifier).changeNetwork(network),
              ),
          ]),
          _Section('Appearance', [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AppThemeMode>(
                      key: const Key('theme_dropdown'),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: AppThemeMode.system,
                          label: Text('Auto'),
                          icon: Icon(Icons.brightness_auto_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: AppThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: AppThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded, size: 18),
                        ),
                      ],
                      selected: {settings.theme},
                      onSelectionChanged: (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .changeTheme(value.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ]),
          _Section('Security', [
            SwitchListTile(
              key: const Key('biometric_switch'),
              secondary: const Icon(Icons.fingerprint_rounded),
              title: const Text('Biometric unlock'),
              subtitle: biometricAvailable
                  ? null
                  : const Text('Not available on this device'),
              value: biometricEnabled,
              onChanged: biometricAvailable
                  ? (value) async {
                      try {
                        await ref.read(enableBiometricProvider)(value);
                        ref.invalidate(biometricEnabledProvider);
                      } catch (e) {
                        if (context.mounted) {
                          showMessage(context, errorMessage(e));
                        }
                      }
                    }
                  : null,
            ),
            ListTile(
              key: const Key('show_seed'),
              leading: const Icon(Icons.vpn_key_rounded),
              title: const Text('Show seed phrase'),
              onTap: () => _showSeed(context, ref),
            ),
            ListTile(
              key: const Key('lock_now'),
              leading: const Icon(Icons.lock_rounded),
              title: const Text('Lock wallet'),
              onTap: () {
                ref.read(sessionProvider.notifier).lock();
              },
            ),
          ]),
          _Section('Danger zone', [
            ListTile(
              key: const Key('delete_wallet'),
              leading: Icon(Icons.delete_forever_rounded,
                  color: Theme.of(context).colorScheme.error),
              title: Text(
                'Delete wallet from this device',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => _delete(context, ref),
            ),
          ]),
        ],
      ),
    );
  }
  Future<void> _showSeed(BuildContext context, WidgetRef ref) async {
    final token =
        await confirmAuth(context, ref, reason: 'Show seed phrase');
    if (token == null || !context.mounted) return;
    try {
      final mnemonic = await ref.read(exportWalletProvider)(
        token,
        ref.read(sessionProvider.notifier).unlockedMnemonic ?? '',
      );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Seed phrase'),
          content: Text(mnemonic, key: const Key('seed_text')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) showMessage(context, errorMessage(e));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete wallet?'),
        content: const Text(
          'The wallet will be removed from this device. Without your seed phrase '
          'the funds cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm_delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final token = await confirmAuth(context, ref, reason: 'Delete wallet');
    if (token == null || !context.mounted) return;
    try {
      await ref.read(onboardingServiceProvider).resetWallet();
    } catch (e) {
      if (context.mounted) showMessage(context, errorMessage(e));
    }
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
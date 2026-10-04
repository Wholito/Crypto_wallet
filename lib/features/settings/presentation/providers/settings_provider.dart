import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../../shared/models/network.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/settings_usecases.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(settingsBoxProvider)),
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> changeNetwork(Network network) async {
    await ChangeNetwork(ref.read(settingsRepositoryProvider))(network);
    state = state.copyWith(network: network);
  }

  Future<void> changeTheme(AppThemeMode theme) async {
    await ChangeTheme(ref.read(settingsRepositoryProvider))(theme);
    state = state.copyWith(theme: theme);
  }

  Future<void> changeCurrency(String currency) async {
    await ChangeCurrency(ref.read(settingsRepositoryProvider))(currency);
    state = state.copyWith(currency: currency);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final currentNetworkProvider =
    Provider<Network>((ref) => ref.watch(settingsProvider.select((s) => s.network)));

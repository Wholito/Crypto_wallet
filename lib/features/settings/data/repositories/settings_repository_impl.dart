import 'package:hive/hive.dart';

import '../../../../core/constants/networks.dart';
import '../../../../shared/models/network.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._box);

  final Box<String> _box;

  static const _networkKey = 'network';
  static const _themeKey = 'theme';
  static const _currencyKey = 'currency';

  @override
  AppSettings load() => AppSettings(
        network: Networks.byId(_box.get(_networkKey)),
        theme: AppThemeMode.values.firstWhere(
          (t) => t.name == _box.get(_themeKey),
          orElse: () => AppThemeMode.system,
        ),
        currency: _box.get(_currencyKey) ?? 'USD',
      );

  @override
  Future<void> saveNetwork(Network network) => _box.put(_networkKey, network.id);

  @override
  Future<void> saveTheme(AppThemeMode theme) => _box.put(_themeKey, theme.name);

  @override
  Future<void> saveCurrency(String currency) => _box.put(_currencyKey, currency);
}

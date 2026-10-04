import '../../../../shared/models/network.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class ChangeNetwork {
  const ChangeNetwork(this._repository);

  final SettingsRepository _repository;

  Future<void> call(Network network) => _repository.saveNetwork(network);
}

class ChangeTheme {
  const ChangeTheme(this._repository);

  final SettingsRepository _repository;

  Future<void> call(AppThemeMode theme) => _repository.saveTheme(theme);
}

class ChangeCurrency {
  const ChangeCurrency(this._repository);

  final SettingsRepository _repository;

  Future<void> call(String currency) => _repository.saveCurrency(currency);
}

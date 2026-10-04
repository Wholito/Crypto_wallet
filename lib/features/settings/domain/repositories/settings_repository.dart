import '../../../../shared/models/network.dart';
import '../entities/app_settings.dart';

abstract class SettingsRepository {
  AppSettings load();

  Future<void> saveNetwork(Network network);

  Future<void> saveTheme(AppThemeMode theme);

  Future<void> saveCurrency(String currency);
}

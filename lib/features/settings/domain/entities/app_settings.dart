import 'package:equatable/equatable.dart';

import '../../../../shared/models/network.dart';

enum AppThemeMode { system, light, dark }

class AppSettings extends Equatable {
  const AppSettings({
    required this.network,
    this.theme = AppThemeMode.system,
    this.currency = 'USD',
  });

  final Network network;
  final AppThemeMode theme;
  final String currency;

  AppSettings copyWith({Network? network, AppThemeMode? theme, String? currency}) =>
      AppSettings(
        network: network ?? this.network,
        theme: theme ?? this.theme,
        currency: currency ?? this.currency,
      );

  @override
  List<Object?> get props => [network, theme, currency];
}

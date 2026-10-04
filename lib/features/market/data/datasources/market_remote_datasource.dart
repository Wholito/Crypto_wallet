import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';

class MarketRemoteDataSource {
  const MarketRemoteDataSource(this._client);

  final http.Client _client;

  bool get isConfigured => AppConstants.backendUrl.isNotEmpty;

  Future<Map<String, Map<String, dynamic>>> fetch(
    List<String> symbols,
    String currency,
  ) async {
    if (!isConfigured || symbols.isEmpty) return const {};
    try {
      final uri = Uri.parse('${AppConstants.backendUrl}/market/prices').replace(
        queryParameters: {'symbols': symbols.join(','), 'currency': currency},
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw const NetworkFailure();
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['prices'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
    } catch (e) {
      throw Failure.from(e);
    }
  }
}

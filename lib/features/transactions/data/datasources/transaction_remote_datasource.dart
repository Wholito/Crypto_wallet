import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/network.dart';

class TransactionRemoteDataSource {
  const TransactionRemoteDataSource(this._client, this._network);

  final http.Client _client;
  final Network _network;

  bool get isConfigured =>
      AppConstants.backendUrl.isNotEmpty ||
      AppConstants.etherscanApiKey.isNotEmpty;

  Uri _uri(String address) {
    if (AppConstants.backendUrl.isNotEmpty) {
      return Uri.parse('${AppConstants.backendUrl}/wallet/$address/transactions')
          .replace(queryParameters: {'chain_id': '${_network.chainId}'});
    }
    return Uri.https('api.etherscan.io', '/v2/api', {
      'chainid': '${_network.chainId}',
      'module': 'account',
      'action': 'txlist',
      'address': address,
      'startblock': '0',
      'endblock': '99999999',
      'page': '1',
      'offset': '50',
      'sort': 'desc',
      'apikey': AppConstants.etherscanApiKey,
    });
  }

  Future<List<Map<String, dynamic>>> fetch(String address) async {
    if (!isConfigured) return const [];
    try {
      final response = await _client
          .get(_uri(address))
          .timeout(AppConstants.rpcTimeout);
      if (response.statusCode != 200) throw const NetworkFailure();
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final result = body['result'];
      if (result is List) {
        return [
          for (final item in result)
            if (item is Map<String, dynamic>) item,
        ];
      }
      if (body['message'] == 'No transactions found') return const [];
      throw const NetworkFailure('Transaction history is unavailable.');
    } catch (e) {
      throw Failure.from(e);
    }
  }
}

import 'package:equatable/equatable.dart';

class NativeCurrency extends Equatable {
  const NativeCurrency({
    required this.name,
    required this.symbol,
    this.decimals = 18,
  });

  final String name;
  final String symbol;
  final int decimals;

  @override
  List<Object?> get props => [name, symbol, decimals];
}

class TokenInfo extends Equatable {
  const TokenInfo({
    required this.symbol,
    required this.name,
    required this.contractAddress,
    required this.decimals,
  });

  final String symbol;
  final String name;
  final String contractAddress;
  final int decimals;

  @override
  List<Object?> get props => [contractAddress.toLowerCase()];
}

class Network extends Equatable {
  const Network({
    required this.id,
    required this.name,
    required this.chainId,
    required this.rpcUrl,
    required this.explorerUrl,
    required this.nativeCurrency,
    this.isTestnet = false,
    this.tokens = const [],
  });

  final String id;
  final String name;
  final int chainId;
  final String rpcUrl;
  final String explorerUrl;
  final NativeCurrency nativeCurrency;
  final bool isTestnet;
  final List<TokenInfo> tokens;

  String txUrl(String hash) => '$explorerUrl/tx/$hash';

  @override
  List<Object?> get props => [id, chainId, rpcUrl];
}

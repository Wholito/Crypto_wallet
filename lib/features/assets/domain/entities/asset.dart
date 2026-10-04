import 'package:equatable/equatable.dart';

import '../../../../core/utils/units.dart';

class Asset extends Equatable {
  const Asset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.decimals,
    required this.balance,
    this.contractAddress,
    this.price,
    this.priceChange24h,
    this.logo,
  });

  final String id;
  final String symbol;
  final String name;
  final String? contractAddress;
  final int decimals;
  final BigInt balance;
  final double? price;
  final double? priceChange24h;
  final String? logo;

  String get formattedBalance => Units.format(balance, decimals, maxFraction: 6);

  double get balanceAsDouble => double.parse(Units.format(balance, decimals));

  double? get fiatValue => price == null ? null : balanceAsDouble * price!;

  Asset copyWith({double? price, double? priceChange24h, BigInt? balance}) => Asset(
        id: id,
        symbol: symbol,
        name: name,
        decimals: decimals,
        balance: balance ?? this.balance,
        contractAddress: contractAddress,
        price: price ?? this.price,
        priceChange24h: priceChange24h ?? this.priceChange24h,
        logo: logo,
      );

  @override
  List<Object?> get props => [id, balance, price, priceChange24h];
}

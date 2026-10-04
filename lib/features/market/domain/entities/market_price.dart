import 'package:equatable/equatable.dart';

class MarketPrice extends Equatable {
  const MarketPrice({required this.symbol, required this.price, this.change24h});

  final String symbol;
  final double price;
  final double? change24h;

  @override
  List<Object?> get props => [symbol, price, change24h];
}

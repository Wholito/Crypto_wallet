import 'dart:convert';

import '../../domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.id,
    required super.address,
    required super.network,
    required super.createdAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id'] as String,
        address: json['address'] as String,
        network: json['network'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  factory WalletModel.decode(String source) =>
      WalletModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
        'id': id,
        'address': address,
        'network': network,
        'createdAt': createdAt.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());
}

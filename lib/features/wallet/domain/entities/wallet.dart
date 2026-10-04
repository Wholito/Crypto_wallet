import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  const Wallet({
    required this.id,
    required this.address,
    required this.network,
    required this.createdAt,
  });

  final String id;
  final String address;
  final String network;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, address, network, createdAt];
}

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/json_rpc.dart';

sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;

  static Failure from(Object error) {
    if (error is Failure) return error;
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException) {
      return const NetworkFailure();
    }
    if (error is RPCError) {
      final text = error.message.toLowerCase();
      if (text.contains('insufficient funds')) {
        return const InsufficientBalanceFailure();
      }
      if (text.contains('nonce too low') || text.contains('already known')) {
        return const TransactionFailure('Transaction already submitted.');
      }
      if (text.contains('underpriced') || text.contains('fee too low')) {
        return const TransactionFailure('Gas fee is too low. Try again.');
      }
      if (text.contains('nonce')) {
        return const TransactionFailure('Unable to submit transaction.');
      }
      return const NetworkFailure('Blockchain request failed.');
    }
    developer.log('$error', name: 'Failure', error: error);
    return const UnknownFailure();
  }
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Check your connection.']);
}

class WalletFailure extends Failure {
  const WalletFailure([super.message = 'Wallet error.']);
}

class InvalidAddressFailure extends Failure {
  const InvalidAddressFailure([super.message = 'Invalid address.']);
}

class InvalidAmountFailure extends Failure {
  const InvalidAmountFailure([super.message = 'Invalid amount.']);
}

class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure([super.message = 'Insufficient balance.']);
}

class TransactionFailure extends Failure {
  const TransactionFailure([super.message = 'Transaction failed.']);
}

class GasEstimationFailure extends Failure {
  const GasEstimationFailure([super.message = 'Unable to estimate gas.']);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'Authentication failed.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage error.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}

import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/network.dart';
import '../../../transactions/domain/entities/wallet_transaction.dart';

class BlockchainDataSource {
  BlockchainDataSource(this.network, this._http)
      : _client = Web3Client(network.rpcUrl, _http);

  final Network network;
  final http.Client _http;
  final Web3Client _client;

  Future<T> _guarded<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(AppConstants.rpcTimeout);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<BigInt> getBalance(String address) => _guarded(() async {
        final amount =
            await _client.getBalance(EthereumAddress.fromHex(address));
        return amount.getInWei;
      });

  static const _erc20Abi =
      '[{"constant":true,"inputs":[{"name":"owner","type":"address"}],'
      '"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],'
      '"stateMutability":"view","type":"function"}]';

  Future<BigInt> getTokenBalance(String address, String contract) =>
      _guarded(() async {
        final deployed = DeployedContract(
          ContractAbi.fromJson(_erc20Abi, 'ERC20'),
          EthereumAddress.fromHex(contract),
        );
        final result = await _client.call(
          contract: deployed,
          function: deployed.function('balanceOf'),
          params: [EthereumAddress.fromHex(address)],
        );
        return result.first as BigInt;
      });

  Future<({BigInt gasLimit, BigInt gasPrice})> estimateFee({
    required String from,
    required String to,
    required BigInt amount,
  }) async {
    try {
      final result = await () async {
        final gasLimit = await _client.estimateGas(
          sender: EthereumAddress.fromHex(from),
          to: EthereumAddress.fromHex(to),
          value: EtherAmount.inWei(amount),
        );
        final price = (await _client.getGasPrice()).getInWei;
        final margin = BigInt.from(100 + AppConstants.gasPriceMarginPercent);
        return (
          gasLimit: gasLimit,
          gasPrice: price * margin ~/ BigInt.from(100),
        );
      }()
          .timeout(AppConstants.rpcTimeout);
      return result;
    } catch (e) {
      final failure = Failure.from(e);
      if (e is RPCError && failure is! InsufficientBalanceFailure) {
        throw const GasEstimationFailure();
      }
      throw failure;
    }
  }

  Future<String> signAndSend({
    required EthPrivateKey credentials,
    required String to,
    required BigInt amount,
    required BigInt gasLimit,
    required BigInt gasPrice,
  }) async {
    try {
      return await () async {
        final nonce = await _client.getTransactionCount(
          credentials.address,
          atBlock: const BlockNum.pending(),
        );
        final tx = Transaction(
          to: EthereumAddress.fromHex(to),
          value: EtherAmount.inWei(amount),
          gasPrice: EtherAmount.inWei(gasPrice),
          maxGas: gasLimit.toInt(),
          nonce: nonce,
        );
        final Uint8List signed = await _client.signTransaction(
          credentials,
          tx,
          chainId: network.chainId,
        );
        return await _client.sendRawTransaction(signed);
      }()
          .timeout(AppConstants.rpcTimeout);
    } catch (e) {
      final failure = Failure.from(e);
      if (failure is NetworkFailure || failure is UnknownFailure) {
        throw TransactionFailure(failure.message);
      }
      throw failure;
    }
  }

  Future<TxStatus?> receiptStatus(String hash) => _guarded(() async {
        final receipt = await _client.getTransactionReceipt(hash);
        if (receipt == null) return null;
        return receipt.status == false ? TxStatus.failed : TxStatus.confirmed;
      });

  void dispose() {
    _client.dispose();
    _http.close();
  }
}

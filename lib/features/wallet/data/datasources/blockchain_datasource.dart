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

  static const _erc20Abi =
      '['
      '{"constant":true,"inputs":[{"name":"owner","type":"address"}],'
      '"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],'
      '"stateMutability":"view","type":"function"},'
      '{"constant":false,"inputs":[{"name":"to","type":"address"},'
      '{"name":"value","type":"uint256"}],"name":"transfer",'
      '"outputs":[{"name":"","type":"bool"}],'
      '"stateMutability":"nonpayable","type":"function"}'
      ']';

  Future<T> _guarded<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(AppConstants.rpcTimeout);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  DeployedContract _erc20(String contract) => DeployedContract(
        ContractAbi.fromJson(_erc20Abi, 'ERC20'),
        EthereumAddress.fromHex(contract),
      );

  Uint8List encodeErc20Transfer(String contract, String to, BigInt amount) {
    final deployed = _erc20(contract);
    return deployed.function('transfer').encodeCall([
      EthereumAddress.fromHex(to),
      amount,
    ]);
  }

  Future<BigInt> getBalance(String address) => _guarded(() async {
        final amount =
            await _client.getBalance(EthereumAddress.fromHex(address));
        return amount.getInWei;
      });

  Future<BigInt> getTokenBalance(String address, String contract) =>
      _guarded(() async {
        final deployed = _erc20(contract);
        final result = await _client.call(
          contract: deployed,
          function: deployed.function('balanceOf'),
          params: [EthereumAddress.fromHex(address)],
        );
        return result.first as BigInt;
      });

  Future<bool> isContract(String address) => _guarded(() async {
        final code = await _client.getCode(EthereumAddress.fromHex(address));
        return code.isNotEmpty;
      });

  Future<FeeEstimate> estimateFee({
    required String from,
    required String to,
    required BigInt amount,
    String? tokenContract,
  }) async {
    try {
      return await () async {
        final data = tokenContract == null
            ? null
            : encodeErc20Transfer(tokenContract, to, amount);
        final target = tokenContract ?? to;
        final value =
            tokenContract == null ? EtherAmount.inWei(amount) : EtherAmount.zero();
        final gasLimit = await _client.estimateGas(
          sender: EthereumAddress.fromHex(from),
          to: EthereumAddress.fromHex(target),
          value: value,
          data: data,
        );
        final padded = gasLimit *
            BigInt.from(100 + AppConstants.gasLimitMarginPercent) ~/
            BigInt.from(100);
        final block = await _client.getBlockInformation();
        final base = block.baseFeePerGas?.getInWei;
        if (base != null) {
          final tip = BigInt.from(1500000000);
          final maxFee = (base * BigInt.from(2)) + tip;
          final margin = BigInt.from(100 + AppConstants.gasPriceMarginPercent);
          return FeeEstimate(
            gasLimit: padded,
            maxFeePerGas: maxFee * margin ~/ BigInt.from(100),
            maxPriorityFeePerGas: tip,
          );
        }
        final price = (await _client.getGasPrice()).getInWei;
        final margin = BigInt.from(100 + AppConstants.gasPriceMarginPercent);
        final paddedPrice = price * margin ~/ BigInt.from(100);
        return FeeEstimate(
          gasLimit: padded,
          maxFeePerGas: paddedPrice,
          maxPriorityFeePerGas: paddedPrice,
        );
      }()
          .timeout(AppConstants.rpcTimeout);
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
    required FeeEstimate estimate,
    String? tokenContract,
  }) async {
    try {
      return await () async {
        final nonce = await _client.getTransactionCount(
          credentials.address,
          atBlock: const BlockNum.pending(),
        );
        final data = tokenContract == null
            ? null
            : encodeErc20Transfer(tokenContract, to, amount);
        final target = tokenContract ?? to;
        final value =
            tokenContract == null ? EtherAmount.inWei(amount) : EtherAmount.zero();
        final tx = Transaction(
          to: EthereumAddress.fromHex(target),
          value: value,
          data: data,
          maxGas: estimate.gasLimit.toInt(),
          maxFeePerGas: EtherAmount.inWei(estimate.maxFeePerGas),
          maxPriorityFeePerGas:
              EtherAmount.inWei(estimate.maxPriorityFeePerGas),
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

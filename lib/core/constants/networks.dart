import '../../shared/models/network.dart';

abstract final class Networks {
  static const sepolia = Network(
    id: 'sepolia',
    name: 'Sepolia Testnet',
    chainId: 11155111,
    rpcUrl: 'https://ethereum-sepolia-rpc.publicnode.com',
    explorerUrl: 'https://sepolia.etherscan.io',
    nativeCurrency: NativeCurrency(name: 'Sepolia Ether', symbol: 'SepoliaETH'),
    isTestnet: true,
  );

  static const ethereum = Network(
    id: 'ethereum',
    name: 'Ethereum',
    chainId: 1,
    rpcUrl: 'https://ethereum-rpc.publicnode.com',
    explorerUrl: 'https://etherscan.io',
    nativeCurrency: NativeCurrency(name: 'Ether', symbol: 'ETH'),
  );

  static const polygon = Network(
    id: 'polygon',
    name: 'Polygon',
    chainId: 137,
    rpcUrl: 'https://polygon-bor-rpc.publicnode.com',
    explorerUrl: 'https://polygonscan.com',
    nativeCurrency: NativeCurrency(name: 'POL', symbol: 'POL'),
  );

  static const bnb = Network(
    id: 'bnb',
    name: 'BNB Chain',
    chainId: 56,
    rpcUrl: 'https://bsc-rpc.publicnode.com',
    explorerUrl: 'https://bscscan.com',
    nativeCurrency: NativeCurrency(name: 'BNB', symbol: 'BNB'),
    tokens: [
      TokenInfo(
        symbol: 'USDT',
        name: 'Tether USD',
        contractAddress: '0x55d398326f99059fF775485246999027B3197955',
        decimals: 18,
      ),
    ],
  );

  static const all = [sepolia, ethereum, polygon, bnb];
  static const defaultNetwork = sepolia;

  static Network byId(String? id) =>
      all.firstWhere((n) => n.id == id, orElse: () => defaultNetwork);
}

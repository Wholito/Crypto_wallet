abstract final class AppConstants {
  static const derivationPath = "m/44'/60'/0'/0/0";
  static const pinLength = 6;
  static const maxPinAttempts = 5;
  static const lockoutSeconds = [30, 120, 600];
  static const autoLockSeconds = 60;
  static const etherscanApiKey = String.fromEnvironment('ETHERSCAN_API_KEY');
  static const backendUrl = String.fromEnvironment('BACKEND_URL');
  static const gasPriceMarginPercent = 20;
  static const gasLimitMarginPercent = 20;
  static const rpcTimeout = Duration(seconds: 15);
  static const pendingTxTimeout = Duration(minutes: 30);
  static const zeroAddress = '0x0000000000000000000000000000000000000000';
}

extension AddressX on String {
  String get shortAddress =>
      length < 12 ? this : '${substring(0, 6)}...${substring(length - 4)}';
}

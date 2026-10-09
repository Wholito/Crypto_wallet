class AuthorizationToken {
  AuthorizationToken._(this._nonce);

  final int _nonce;
  static int _seq = 0;
  static final _valid = <int>{};

  factory AuthorizationToken.issue() {
    final token = AuthorizationToken._(++_seq);
    _valid.add(token._nonce);
    return token;
  }

  bool get isValid => _valid.contains(_nonce);

  void consume() => _valid.remove(_nonce);

  static void invalidateAll() => _valid.clear();
}

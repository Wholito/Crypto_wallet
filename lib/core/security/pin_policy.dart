abstract final class PinPolicy {
  static const trivial = {
    '000000',
    '111111',
    '222222',
    '333333',
    '444444',
    '555555',
    '666666',
    '777777',
    '888888',
    '999999',
    '123456',
    '654321',
    '112233',
    '121212',
  };

  static bool isTrivial(String pin) {
    if (trivial.contains(pin)) return true;
    if (pin.split('').toSet().length == 1) return true;
    var ascending = true;
    var descending = true;
    for (var i = 1; i < pin.length; i++) {
      final prev = int.parse(pin[i - 1]);
      final curr = int.parse(pin[i]);
      if (curr != (prev + 1) % 10) ascending = false;
      if (curr != (prev + 9) % 10) descending = false;
    }
    return ascending || descending;
  }
}

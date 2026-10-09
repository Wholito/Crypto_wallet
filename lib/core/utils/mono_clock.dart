abstract final class MonoClock {
  static final _watch = Stopwatch()..start();
  static final int _wallOrigin = DateTime.now().toUtc().millisecondsSinceEpoch;

  static int nowMs() => _wallOrigin + _watch.elapsedMilliseconds;
}

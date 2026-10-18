/// One shared prototype clock for tracking, timeline, and the home page.
class DeliveryClock {
  static const duration = Duration(seconds: 75);
  static double fraction(DateTime startedAt) =>
      (DateTime.now().difference(startedAt).inMilliseconds /
        duration.inMilliseconds).clamp(0.0, 1.0);
  static int etaMinutes(DateTime startedAt) {
    final remaining = 1.0 - fraction(startedAt);
    if (remaining <= 0) return 0;
    return (remaining * 3).ceil();
  }
  static double stageThreshold(int index) => switch (index) {
    0 => 0.0, 1 => 0.03, 2 => 0.14, 3 => 0.28, _ => 1.0,
  };
  static int stage(DateTime startedAt) {
    final p = fraction(startedAt);
    if (p >= 1) return 4;
    if (p >= 0.28) return 3;
    if (p >= 0.14) return 2;
    if (p >= 0.03) return 1;
    return 0;
  }
}

class Measure {
  int _end = 0;
  int _start = 0;

  bool get isMeasuring => _start != 0;

  Measure();

  Measure.withStart({required int start}) : _start = start;

  void startMeasure() {
    _start = DateTime.now().millisecondsSinceEpoch;
  }

  void endMeasure() {
    _end = DateTime.now().millisecondsSinceEpoch;
  }

  String get duration => ((_end - _start) / 1000).toDouble().toStringAsFixed(2);

  void clear() {
    _start = 0;
    _end = 0;
  }
}

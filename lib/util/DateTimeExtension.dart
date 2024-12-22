
extension DateTimeExt on DateTime {
  int get secondsSinceEpoch => (millisecondsSinceEpoch/1000).round();
}
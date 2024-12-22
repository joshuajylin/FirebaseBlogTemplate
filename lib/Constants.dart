
class Constants {
  static const String _version = "1.0.0";
  static bool get isDebug => const bool.fromEnvironment("DEBUG");
  static String get timestamp => const String.fromEnvironment("TIMESTAMP");
  static String get version => 'V$_version-$timestamp';
}

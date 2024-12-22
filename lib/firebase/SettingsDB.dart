import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/WebsiteSettings.dart';

class SettingsDB {
  static late final SettingsDB _instance = SettingsDB._internal();
  static SettingsDB get instance => _instance;
  factory SettingsDB() => _instance;

  static const String _collectionName = 'settings';
  static const String _documentName = 'global';
  static const int _timeoutSeconds = 60 * 10;

  final DocumentReference<Map<String, dynamic>> _defDocRef = FirebaseFirestore.instance.collection(_collectionName).doc(_documentName);
  late DocumentSnapshot<Map<String, dynamic>> _snapshot;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _fetching = false;

  SettingsDB._internal() {
    _getUpToDateSnapshot();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUpToDateSnapshot() async {
    if (!_fetching && (DateTime.now().difference(_lastUpdate).inSeconds > _timeoutSeconds)) {
      _fetching = true;
      _snapshot = await _defDocRef.get();
      _lastUpdate = DateTime.now();
      _fetching = false;
    }
    if (_fetching) {
      await Future.doWhile(() => Future.delayed(const Duration(milliseconds: 200)).then((_) => _fetching));
    }
    return _snapshot;
  }

  Future<WebsiteSettings> get() async {
    final snapshot = await _getUpToDateSnapshot();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return WebsiteSettings.defaultSettings;
    }
    return WebsiteSettings.fromJson(data);
  }

  Future<void> set(WebsiteSettings settings) async {
    await _defDocRef.set(settings.toJson());
    _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  }

}

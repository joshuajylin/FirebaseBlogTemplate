import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/WebsiteTheme.dart';


class ThemesDB {
  static late final ThemesDB _instance = ThemesDB._internal();
  static ThemesDB get instance => _instance;
  factory ThemesDB() => _instance;

  static const String _collectionName = 'themes';
  static final String _documentName = WebsiteThemeTypes.customized.name;
  static const int _timeoutSeconds = 60 * 10;

  final DocumentReference<Map<String, dynamic>> _defDocRef = FirebaseFirestore.instance.collection(_collectionName).doc(_documentName);
  late DocumentSnapshot<Map<String, dynamic>> _snapshot;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _fetching = false;

  ThemesDB._internal() {
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

  Future<WebsiteTheme> _get({WebsiteTheme? defaultTheme}) async {
    final snapshot = await _getUpToDateSnapshot();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return defaultTheme ?? WebsiteTheme.defaultTheme;
    }
    return WebsiteTheme.fromJson(data);
  }

  Future<void> set(WebsiteTheme theme) async {
    await _defDocRef.set(theme.toJson());
    _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<WebsiteTheme> getTheme(String name, {WebsiteTheme? defaultTheme}) async {
    if (name == _documentName) {
      return _get(defaultTheme: defaultTheme);
    }
    else if (WebsiteThemeTypes.values.map((e) => e.name).contains(name)) {
      return WebsiteThemeTypes.values.byName(name).theme;
    }
    else {
      return defaultTheme ?? WebsiteTheme.defaultTheme;
    }
  }
}

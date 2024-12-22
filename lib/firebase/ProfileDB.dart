import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/Article.dart';


class ProfileDB {
  static late final ProfileDB _instance = ProfileDB._internal();
  static ProfileDB get instance => _instance;
  factory ProfileDB() => _instance;

  static const String _collectionName = 'profile';
  static const String _meDocName = 'aboutMe';
  static const int _timeoutSeconds = 60 * 10;

  final CollectionReference<Map<String, dynamic>> _defColRef = FirebaseFirestore.instance.collection(_collectionName);
  late QuerySnapshot<Map<String, dynamic>> _snapshot;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _fetching = false;

  ProfileDB._internal() {
    _getUpToDateSnapshot();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getUpToDateSnapshot() async {
    if (!_fetching && (DateTime.now().difference(_lastUpdate).inSeconds > _timeoutSeconds)) {
      _fetching = true;
      _snapshot = await _defColRef.get();
      _lastUpdate = DateTime.now();
      _fetching = false;
    }
    if (_fetching) {
      await Future.doWhile(() => Future.delayed(const Duration(milliseconds: 200)).then((_) => _fetching));
    }
    return _snapshot;
  }

  Future<Article?> getAboutMe({Article? defaultArticle}) async {
    final snapshot = await _getUpToDateSnapshot();
    final docRefs = snapshot.docs.map<DocumentReference<Map<String, dynamic>>>((e) => e.reference).toList();
    Article? article;
    for (var element in docRefs) {
      if (element.path.split('/').last == _meDocName) {
        final docSnapshot = await element.get();
        final data = docSnapshot.data();
        if (data != null) {
          article = Article.fromJson(data);
        }
      }
    }

    if (article == null) {
      article = defaultArticle;
      article?.path = '$_collectionName/$_meDocName';
    }
    return article;
  }

  Future<Article> setAboutMe(Article article) async {
    final docRef = _defColRef.doc(_meDocName);
    article.path = docRef.path;
    await docRef.set(article.toJson());
    return article;
  }

}
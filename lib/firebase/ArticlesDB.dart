import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_blog_template/util/StringExtension.dart';

import '../models/Article.dart';

class ArticlesDB {
  static late final ArticlesDB _instance = ArticlesDB._internal();
  static ArticlesDB get instance => _instance;
  factory ArticlesDB() => _instance;

  static const String _collectionName = 'articles';
  static const String _introDocName = 'introduction';
  static const int _timeoutSeconds = 60 * 10;

  final CollectionReference<Map<String, dynamic>> _defColRef = FirebaseFirestore.instance.collection(_collectionName);
  late QuerySnapshot<Map<String, dynamic>> _snapshot;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _fetching = false;

  ArticlesDB._internal() {
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

  Future<List<Article>> get({String? tag, String? keyword, bool unpublished = false}) async {
    final snapshot = await _getUpToDateSnapshot();
    List<Article> articles = snapshot.docs.map<Article>((e) {
      final path = e.reference.path;
      var data = e.data();
      data['path'] = path;
      return Article.fromJson(data);
    }).toList();
    articles.removeWhere((element) => element.path == '$_collectionName/$_introDocName');
    if (tag?.isNotEmpty ?? false) {
      articles = articles.where((article) => article.tags.contains(tag)).toList();
    }
    if (keyword?.isNotEmpty ?? false) {
      articles = articles.where((article) => article.content.contains(keyword!)).toList();
    }
    if (unpublished) {
      articles = articles.where((article) => !article.isPublished).toList();
    }
    articles.sort((a, b) => b.publishingTime.compareTo(a.publishingTime));
    return articles;
  }

  Future<Article?> getIntroduction({Article? defaultArticle}) async {
    final snapshot = await _getUpToDateSnapshot();
    final docRefs = snapshot.docs.map<DocumentReference<Map<String, dynamic>>>((e) => e.reference).toList();
    Article? article;
    for (var element in docRefs) {
      if (element.path.split('/').last == _introDocName) {
        final docSnapshot = await element.get();
        final data = docSnapshot.data();
        if (data != null) {
          article = Article.fromJson(data);
        }
      }
    }

    if (article == null) {
      article = defaultArticle;
      article?.path = '$_collectionName/$_introDocName';
    }
    return article;
  }

  Future<Article> set(Article article) async {
    final docName = article.path?.split('/').last;
    final docRef = _defColRef.doc(docName);
    article.path ??= docRef.path;
    await docRef.set(article.toJson());
    return article;
  }

  Future<Article> setIntroduction(Article article) async {
    final docRef = _defColRef.doc(_introDocName);
    article.path = docRef.path;
    await docRef.set(article.toJson());
    return article;
  }

  Future<void> delete(Article article) async {
    final docName = article.path?.split('/').last;
    if (docName != null) {
      final docRef = _defColRef.doc(docName);
      await docRef.delete();
    }
  }

}
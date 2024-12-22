import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_blog_template/models/UserAccountInfo.dart';
import 'package:firebase_blog_template/models/UserProfile.dart';
import 'package:firebase_blog_template/util/StringExtension.dart';

import 'package:http/http.dart' as http;

class UserAccount {

  static late final UserAccount _instance = UserAccount._internal();
  static UserAccount get instance => _instance;
  factory UserAccount() => _instance;

  static const String _collectionName = 'users';
  static const int _timeoutSeconds = 60 * 10;

  DocumentSnapshot<Map<String, dynamic>>? _snapshot;

  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _fetching = false;
  UserAccountInfo? _info;

  bool get isLoggedIn => (FirebaseAuth.instance.currentUser != null);

  UserAccount._internal() {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }
    getUserInfo();
  }

  UserProfile _genDefaultProfile(User user) {
    return UserProfile();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUpToDateSnapshot() async {
    if (!isLoggedIn) {
      return null;
    }
    final user = FirebaseAuth.instance.currentUser!;
    final colRef = FirebaseFirestore.instance.collection(_collectionName);
    final docRef = colRef.doc(user.uid);
    if (!_fetching && (DateTime.now().difference(_lastUpdate).inSeconds > _timeoutSeconds)) {
      _fetching = true;
      _snapshot = await docRef.get();
      if (_snapshot?.exists != true) {
        final defProfile = _genDefaultProfile(user);
        await docRef.set(defProfile.toJson());
        _snapshot = await docRef.get();
      }
      _lastUpdate = DateTime.now();
      _fetching = false;
    }
    if (_fetching) {
      await Future.doWhile(() => Future.delayed(const Duration(milliseconds: 200)).then((_) => _fetching));
    }
    return _snapshot;
  }

  Future<UserAccountInfo?> login() async {
    if (!isLoggedIn) {
      final userAgent = html.window.navigator.userAgent;
      if (userAgent.contains('iOS') || userAgent.contains('iPadOS')) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        await FirebaseAuth.instance.signInWithRedirect(GoogleAuthProvider());
      }
    }
    // NOTE: signInWithRedirect will redirect to IdP's website then redirect back, so code will never get here if not logged in.
    return getUserInfo();
  }

  void logout() {
    _info = null;
    _snapshot = null;
    _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    FirebaseAuth.instance.signOut();
  }

  Future<UserAccountInfo?> getUserInfo() async {
    if (!isLoggedIn) {
      return null;
    }
    if (_info != null) {
      return _info;
    }
    final user = FirebaseAuth.instance.currentUser!;
    UserAccountInfo info = UserAccountInfo(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAdmin: false,
    );

    final snapshot = await _getUpToDateSnapshot();
    final data = snapshot?.data();
    if (data != null) {
      final profile = UserProfile.fromJson(data);
      info.isAdmin = profile.isAdmin;
    }
    if (info.photoUrl != null) {
      final key = info.photoUrl!;
      if (html.window.localStorage.containsKey(key)) {
        String? encoded = html.window.localStorage[key];
        if (encoded?.isNotEmpty ?? false) {
          info.photo = base64Decode(encoded!);
        }
      } else {
        final url = Uri.parse(key);
        final response = await http.get(url);
        info.photo = response.bodyBytes;
        final encoded = base64Encode(response.bodyBytes);
        html.window.localStorage.update(key, (value) => encoded, ifAbsent: () => encoded);
      }
    }
    _info = info;
    return _info;
  }

}
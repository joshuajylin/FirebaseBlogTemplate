import 'package:flutter/cupertino.dart';

class LocaleChangeNotifier with ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  set locale(Locale? l) {
    _locale = l;
    notifyListeners();
  }
}

import 'dart:html' as html;
import 'dart:io';

import 'package:flutter/foundation.dart';

extension PlatformExt on Platform {
  static bool get isPhoneOrTablet {
    bool result = false;
    if (kIsWeb) {
      final userAgent = html.window.navigator.userAgent;
      result =  userAgent.contains('iOS') || userAgent.contains('iPadOS') || userAgent.contains('Android');
    } else {
      result = (Platform.isAndroid || Platform.isIOS);
    }
    return result;
  }

  static bool get isIOS {
    bool result = false;
    if (kIsWeb) {
      final userAgent = html.window.navigator.userAgent;
      result =  userAgent.contains('iOS');
    } else {
      result = Platform.isIOS;
    }
    return result;
  }
}

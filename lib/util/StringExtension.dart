
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

extension StringExt on String {
  void log() => debugPrint(this);

  bool get isValidEmail {
    return RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }

  String get base64UrlDecodedString {
    Codec<String, String> stringToBase64Url = utf8.fuse(base64Url);
    return stringToBase64Url.decode(const Base64Codec().normalize(this));
  }

  String get base64UrlEncode {
    Codec<String, String> stringToBase64Url = utf8.fuse(base64Url);
    return stringToBase64Url.encode(this).replaceAll('=', '');
  }

  Uint8List get base64UrlDecodedData {
    return const Base64Codec().decoder.convert(this);
  }

  Uint8List get uint8List {
    final List<int> codeUnits = this.codeUnits;
    final Uint8List data = Uint8List.fromList(codeUnits);
    return data;
  }

  Size calculateTextSize({required TextStyle style, BuildContext? context}) {
    String text = this;
    final double textScaleFactor = context != null
        ? MediaQuery.of(context).textScaleFactor
        : WidgetsBinding.instance.window.textScaleFactor;

    final TextDirection textDirection =
    context != null ? Directionality.of(context) : TextDirection.ltr;

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    return textPainter.size;
  }

  void asAlertDialog({required BuildContext context, List<Widget>? actions}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          content: Text(this, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
          contentPadding: const EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 10),
          actionsPadding: const EdgeInsets.all(20),
          actions: actions,
        );
      },
    );
  }

  Function() asLoadingIndicator({required BuildContext context}) {
    BuildContext dialogContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        final message = this;
        return AlertDialog(
          title: message.isNotEmpty ? Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ) : null,
          //shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          //shape: const StadiumBorder(),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          content: const SizedBox(
            width: 50,
            height: 50,
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          contentPadding: const EdgeInsets.all(20),
        );
      },
    );
    dismiss() => Navigator.of(dialogContext).pop();
    return dismiss;
  }
}
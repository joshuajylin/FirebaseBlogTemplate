import 'dart:html' as html;

import 'package:firebase_blog_template/models/ArticleTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/Article.dart';

extension ArticleTypesExt on ArticleTypes {
  static ArticleTypes fromName(String name) {
    if (name == ArticleTypes.html.name) {
      return ArticleTypes.html;
    } else if (name == ArticleTypes.markdown.name) {
      return ArticleTypes.markdown;
    } else {
      return ArticleTypes.text;
    }
  }

  Widget getWidget(BuildContext context, String content, {
    required Color textColor,
    TextAlign textAlign = TextAlign.center,
    double fontSize = 20,
  }) {
    Widget widget;
    switch (this) {
      case ArticleTypes.text:
        widget = Text(
          content,
          textAlign: textAlign,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
          ),
        );
      case ArticleTypes.html:
        widget = Html(
          data: content,
          onLinkTap: (url, _, __) {
            if (url != null) {
              html.window.open(url, '');
            }
          },
        );
      case ArticleTypes.markdown:
        widget = MarkdownBody(
          data: content,
          onTapLink: (text, href, title) {
            if (href != null) {
              html.window.open(href, '');
            }
          },
        );
    }
    return widget;
  }
}

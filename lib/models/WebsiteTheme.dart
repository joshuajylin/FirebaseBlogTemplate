import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_gen/gen_l10n/web_localizations.dart';

import 'ArticleTheme.dart';
import 'ToolbarTheme.dart';

part 'WebsiteTheme.g.dart';

@JsonSerializable(explicitToJson: true)
class WebsiteTheme {
  int bgColor;
  int bgBoxColor;
  ToolbarTheme toolbarTheme;
  ArticleTheme articleTheme;

  WebsiteTheme({
    required this.bgColor,
    required this.bgBoxColor,
    required this.toolbarTheme,
    required this.articleTheme,
  });

  factory WebsiteTheme.fromJson(Map<String, dynamic> json) => _$WebsiteThemeFromJson(json);
  Map<String, dynamic> toJson() => _$WebsiteThemeToJson(this);

  static WebsiteTheme get defaultTheme => WebsiteTheme.light;
  static WebsiteTheme get light => WebsiteTheme(
    bgColor: Colors.white.value,
    bgBoxColor: Colors.grey[300]!.value,
    toolbarTheme: ToolbarTheme(
      barColor: Colors.grey[50]!.value,
      bgColor: Colors.grey[200]!.value,
      fgColor: Colors.white.value,
      borderColor: Colors.grey[400]!.value,
      iconColor: Colors.black.value,
      textColor: Colors.black.value,
    ),
    articleTheme: ArticleTheme(
      bgColor: Colors.white.value,
      fgColor: Colors.black.value,
      //coverImage:,
      borderColor: Colors.white.value,
      summaryBoxColor: Colors.white38.value,
      summaryBoxHoverColor: Colors.white54.value,
      summaryTextColor: Colors.black.value,
      contentBgColor: Colors.white.value,
      contentTextColor: Colors.black.value,
      portraitCoverImage: 'bg-portrait-2.png',
      landscapeCoverImage: 'bg-landscape-2.png',
    ),
  );
  static WebsiteTheme get dark => WebsiteTheme(
    bgColor: Colors.black.value,
    bgBoxColor: Colors.grey[850]!.value,
    toolbarTheme: ToolbarTheme(
      barColor: Colors.grey[700]!.value,
      bgColor: Colors.grey[850]!.value,
      fgColor: Colors.white.value,
      borderColor: Colors.white.value,
      iconColor: Colors.white.value,
      textColor: Colors.white.value,
    ),
    articleTheme: ArticleTheme(
      bgColor: Colors.grey[700]!.value,
      fgColor: Colors.white.value,
      //coverImage:,
      borderColor: Colors.grey[700]!.value,
      summaryBoxColor: Colors.black38.value,
      summaryBoxHoverColor: Colors.black54.value,
      summaryTextColor: Colors.white.value,
      contentBgColor: Colors.black.value,
      contentTextColor: Colors.white.value,
      portraitCoverImage: 'bg-portrait-1.png',
      landscapeCoverImage: 'bg-landscape-1.png',
    ),
  );
  static WebsiteTheme get transparent => WebsiteTheme(
    bgColor: Colors.transparent.value,
    bgBoxColor: Colors.transparent.value,
    toolbarTheme: ToolbarTheme(
      barColor: Colors.transparent.value,
      bgColor: Colors.transparent.value,
      fgColor: Colors.transparent.value,
    ),
    articleTheme: ArticleTheme(
      bgColor: Colors.transparent.value,
      fgColor: Colors.transparent.value,
    ),
  );
}

enum WebsiteThemeTypes {
  light,
  dark,
  customized,
}

extension WebsiteThemeTypesExt on WebsiteThemeTypes {
  WebsiteTheme get theme => switch (this) {
    WebsiteThemeTypes.light => WebsiteTheme.light,
    WebsiteThemeTypes.dark => WebsiteTheme.dark,
    WebsiteThemeTypes.customized => WebsiteTheme.transparent,
  };

  String toLocalizedString(AppLocalizations localization) {
    String str;
    switch (this) {
      case WebsiteThemeTypes.light:
        str = localization.light;
      case WebsiteThemeTypes.dark:
        str = localization.dark;
      case WebsiteThemeTypes.customized:
        str = localization.customized;
    }
    return str;
  }
}

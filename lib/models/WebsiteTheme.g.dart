// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'WebsiteTheme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebsiteTheme _$WebsiteThemeFromJson(Map<String, dynamic> json) => WebsiteTheme(
      bgColor: json['bgColor'] as int,
      bgBoxColor: json['bgBoxColor'] as int,
      toolbarTheme:
          ToolbarTheme.fromJson(json['toolbarTheme'] as Map<String, dynamic>),
      articleTheme:
          ArticleTheme.fromJson(json['articleTheme'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WebsiteThemeToJson(WebsiteTheme instance) =>
    <String, dynamic>{
      'bgColor': instance.bgColor,
      'bgBoxColor': instance.bgBoxColor,
      'toolbarTheme': instance.toolbarTheme.toJson(),
      'articleTheme': instance.articleTheme.toJson(),
    };

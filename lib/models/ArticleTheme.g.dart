// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ArticleTheme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArticleTheme _$ArticleThemeFromJson(Map<String, dynamic> json) => ArticleTheme(
      bgColor: json['bgColor'] as int,
      fgColor: json['fgColor'] as int,
      coverImage: json['coverImage'] as String?,
      borderColor: json['borderColor'] as int?,
      summaryBoxColor: json['summaryBoxColor'] as int?,
      summaryBoxHoverColor: json['summaryBoxHoverColor'] as int?,
      summaryTextColor: json['summaryTextColor'] as int?,
      contentBgColor: json['contentBgColor'] as int?,
      contentTextColor: json['contentTextColor'] as int?,
      portraitCoverImage: json['portraitCoverImage'] as String?,
      landscapeCoverImage: json['landscapeCoverImage'] as String?,
    );

Map<String, dynamic> _$ArticleThemeToJson(ArticleTheme instance) =>
    <String, dynamic>{
      'bgColor': instance.bgColor,
      'fgColor': instance.fgColor,
      'borderColor': instance.borderColor,
      'summaryBoxColor': instance.summaryBoxColor,
      'summaryBoxHoverColor': instance.summaryBoxHoverColor,
      'summaryTextColor': instance.summaryTextColor,
      'contentBgColor': instance.contentBgColor,
      'contentTextColor': instance.contentTextColor,
      'coverImage': instance.coverImage,
      'portraitCoverImage': instance.portraitCoverImage,
      'landscapeCoverImage': instance.landscapeCoverImage,
    };

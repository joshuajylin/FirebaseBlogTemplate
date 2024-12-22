// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Article _$ArticleFromJson(Map json) => Article(
      title: json['title'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String,
      summaryType: json['summaryType'] as String,
      contentType: json['contentType'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      creatingTime: json['creatingTime'] as int,
      editingTime: json['editingTime'] as int,
      publishingTime: json['publishingTime'] as int,
      isPublished: json['isPublished'] as bool,
      isUncopiable: json['isUncopiable'] as bool? ?? false,
      path: json['path'] as String?,
      coverImage: json['coverImage'] as String?,
      theme: json['theme'] == null
          ? null
          : ArticleTheme.fromJson(
              Map<String, dynamic>.from(json['theme'] as Map)),
    );

Map<String, dynamic> _$ArticleToJson(Article instance) => <String, dynamic>{
      'title': instance.title,
      'summary': instance.summary,
      'content': instance.content,
      'summaryType': instance.summaryType,
      'contentType': instance.contentType,
      'tags': instance.tags,
      'creatingTime': instance.creatingTime,
      'editingTime': instance.editingTime,
      'publishingTime': instance.publishingTime,
      'isPublished': instance.isPublished,
      'isUncopiable': instance.isUncopiable,
      'path': instance.path,
      'coverImage': instance.coverImage,
      'theme': instance.theme?.toJson(),
    };

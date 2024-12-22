import 'package:json_annotation/json_annotation.dart';

import 'ArticleTheme.dart';

part 'Article.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class Article {
  String title;
  String summary;
  String content;
  String summaryType;
  String contentType;
  List<String> tags;
  int creatingTime;
  int editingTime;
  int publishingTime;
  bool isPublished;
  bool isUncopiable;
  String? path; // path in firestore database
  String? coverImage;
  ArticleTheme? theme;

  Article({
    required this.title,
    required this.summary,
    required this.content,
    required this.summaryType,
    required this.contentType,
    required this.tags,
    required this.creatingTime,
    required this.editingTime,
    required this.publishingTime,
    required this.isPublished,
    this.isUncopiable = false,
    this.path,
    this.coverImage,
    this.theme,
  });

  factory Article.fromJson(Map<String, dynamic> json) => _$ArticleFromJson(json);
  Map<String, dynamic> toJson() => _$ArticleToJson(this);
}

enum ArticleTypes {
  text,
  html,
  markdown,
}

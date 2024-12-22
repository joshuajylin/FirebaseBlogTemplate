import 'package:json_annotation/json_annotation.dart';

part 'ArticleTheme.g.dart';

@JsonSerializable()
class ArticleTheme {
  int bgColor;
  int fgColor;
  int borderColor;
  int summaryBoxColor;
  int summaryBoxHoverColor;
  int summaryTextColor;
  int contentBgColor;
  int contentTextColor;
  String? coverImage;
  String? portraitCoverImage;
  String? landscapeCoverImage;

  ArticleTheme({
    required this.bgColor,
    required this.fgColor,
    this.coverImage,
    int? borderColor,
    int? summaryBoxColor,
    int? summaryBoxHoverColor,
    int? summaryTextColor,
    int? contentBgColor,
    int? contentTextColor,
    String? portraitCoverImage,
    String? landscapeCoverImage,
  }):   this.borderColor = borderColor ?? fgColor,
        this.summaryBoxColor = summaryBoxColor ?? ((bgColor & 0x00FFFFFF) | 0x7F000000),
        this.summaryBoxHoverColor = summaryBoxHoverColor ?? ((bgColor & 0x00FFFFFF) | 0xAA000000),
        this.summaryTextColor = summaryTextColor ?? fgColor,
        this.contentBgColor = contentBgColor ?? bgColor,
        this.contentTextColor = contentTextColor ?? fgColor,
        this.portraitCoverImage = portraitCoverImage ?? coverImage,
        this.landscapeCoverImage = landscapeCoverImage ?? coverImage;

  factory ArticleTheme.fromJson(Map<String, dynamic> json) => _$ArticleThemeFromJson(json);
  Map<String, dynamic> toJson() => _$ArticleThemeToJson(this);
}

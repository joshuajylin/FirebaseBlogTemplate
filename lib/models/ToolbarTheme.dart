import 'package:json_annotation/json_annotation.dart';

part 'ToolbarTheme.g.dart';

@JsonSerializable()
class ToolbarTheme {
  int barColor;
  int bgColor;
  int fgColor;
  int borderColor;
  int iconColor;
  int textColor;

  ToolbarTheme({
    required this.barColor,
    required this.bgColor,
    required this.fgColor,
    int? borderColor,
    int? iconColor,
    int? textColor,
  }):   this.borderColor = borderColor ?? fgColor,
        this.iconColor = iconColor ?? fgColor,
        this.textColor = textColor ?? fgColor;

  factory ToolbarTheme.fromJson(Map<String, dynamic> json) => _$ToolbarThemeFromJson(json);
  Map<String, dynamic> toJson() => _$ToolbarThemeToJson(this);
}

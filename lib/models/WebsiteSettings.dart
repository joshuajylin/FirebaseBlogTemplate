import 'package:json_annotation/json_annotation.dart';

part 'WebsiteSettings.g.dart';

@JsonSerializable()
class WebsiteSettings {
  String title;
  bool adultOnly;
  String theme;

  WebsiteSettings({
    this.title = '',
    this.adultOnly = false,
    this.theme = '',
  });

  factory WebsiteSettings.fromJson(Map<String, dynamic> json) => _$WebsiteSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$WebsiteSettingsToJson(this);

  static WebsiteSettings get defaultSettings {
    return WebsiteSettings(
      title: '',
      adultOnly: false,
      theme: '',
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'WebsiteSettings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebsiteSettings _$WebsiteSettingsFromJson(Map<String, dynamic> json) =>
    WebsiteSettings(
      title: json['title'] as String? ?? '',
      adultOnly: json['adultOnly'] as bool? ?? false,
      theme: json['theme'] as String? ?? '',
    );

Map<String, dynamic> _$WebsiteSettingsToJson(WebsiteSettings instance) =>
    <String, dynamic>{
      'title': instance.title,
      'adultOnly': instance.adultOnly,
      'theme': instance.theme,
    };

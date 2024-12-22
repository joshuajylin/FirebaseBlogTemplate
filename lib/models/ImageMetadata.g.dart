// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ImageMetadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageMetadata _$ImageMetadataFromJson(Map<String, dynamic> json) =>
    ImageMetadata(
      fileExtension: json['fileExtension'] as String,
      bytes: json['bytes'] as int,
      name: json['name'] as String?,
      path: json['path'] as String?,
    )..url = json['url'] as String?;

Map<String, dynamic> _$ImageMetadataToJson(ImageMetadata instance) =>
    <String, dynamic>{
      'fileExtension': instance.fileExtension,
      'bytes': instance.bytes,
      'name': instance.name,
      'path': instance.path,
      'url': instance.url,
    };

import 'package:json_annotation/json_annotation.dart';

part 'ImageMetadata.g.dart';

@JsonSerializable()
class ImageMetadata {
  String fileExtension;
  int bytes;
  String? name;
  String? path;
  String? url;

  ImageMetadata({
    required this.fileExtension,
    required this.bytes,
    this.name,
    this.path,
  });

  factory ImageMetadata.fromJson(Map<String, dynamic> json) => _$ImageMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$ImageMetadataToJson(this);
}
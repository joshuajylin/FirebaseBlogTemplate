import 'package:firebase_blog_template/util/ImageAssets.dart';
import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

part 'WebsiteImage.g.dart';

@JsonSerializable()
class WebsiteImage {
  String name;
  String url;
  String locationType;

  WebsiteImage({
    required this.name,
    required this.url,
    required this.locationType,
  });

  factory WebsiteImage.fromJson(Map<String, dynamic> json) => _$WebsiteImageFromJson(json);
  Map<String, dynamic> toJson() => _$WebsiteImageToJson(this);

  dynamic get image => switch(ImageLocationTypes.values.byName(locationType)) {
    ImageLocationTypes.internal => ImageAssets(name.isNotEmpty ? name : 'transparent.png'),
    ImageLocationTypes.cloudStorage => NetworkImage(url),
    ImageLocationTypes.external => NetworkImage(url),
  };
}

enum ImageLocationTypes {
  internal,
  cloudStorage,
  external,
}

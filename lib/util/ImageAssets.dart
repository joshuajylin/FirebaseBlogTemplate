import 'dart:html' as html;

import 'package:flutter/cupertino.dart';

import '../models/WebsiteImage.dart';

class ImageAssets extends AssetImage {
  static const _path = 'assets/images/';
  const ImageAssets(String imageName): super('$_path$imageName');

  static List<WebsiteImage> get all => [
    WebsiteImage(name: 'bg-landscape-1.png', url: '${html.window.location.origin}/${_path}/bg-landscape-1.png', locationType: ImageLocationTypes.internal.name),
    WebsiteImage(name: 'bg-landscape-2.png', url: '${html.window.location.origin}/${_path}/bg-landscape-2.png', locationType: ImageLocationTypes.internal.name),
    WebsiteImage(name: 'bg-portrait-1.png', url: '${html.window.location.origin}/${_path}/bg-portrait-1.png', locationType: ImageLocationTypes.internal.name),
    WebsiteImage(name: 'bg-portrait-2.png', url: '${html.window.location.origin}/${_path}/bg-portrait-2.png', locationType: ImageLocationTypes.internal.name),
    WebsiteImage(name: 'avatar-1.png', url: '${html.window.location.origin}/${_path}/avatar-1.png', locationType: ImageLocationTypes.internal.name),
    WebsiteImage(name: 'avatar-male-1.png', url: '${html.window.location.origin}/${_path}/avatar-male-1.png', locationType: ImageLocationTypes.internal.name),
    WebsiteImage(name: 'avatar-female-1.png', url: '${html.window.location.origin}/${_path}/avatar-female-1.png', locationType: ImageLocationTypes.internal.name),
  ];
}
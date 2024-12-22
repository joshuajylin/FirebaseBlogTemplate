import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'UserAccountInfo.g.dart';

@JsonSerializable()
class UserAccountInfo {
  String uid;
  String? email;
  String? displayName;
  String? photoUrl;
  bool isAdmin;

  @JsonKey(fromJson: _photoFromJson, toJson: _photoToJson)
  Uint8List? photo;

  UserAccountInfo({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAdmin = false,
  });

  factory UserAccountInfo.fromJson(Map<String, dynamic> json) => _$UserAccountInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserAccountInfoToJson(this);
}

Uint8List? _photoFromJson(String? encoded) => (encoded == null) ? null : base64Decode(encoded);
String? _photoToJson(Uint8List? photo) => (photo == null) ? null : base64Encode(photo);

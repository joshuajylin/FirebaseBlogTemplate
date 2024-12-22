// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserAccountInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAccountInfo _$UserAccountInfoFromJson(Map<String, dynamic> json) =>
    UserAccountInfo(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
    )..photo = _photoFromJson(json['photo'] as String?);

Map<String, dynamic> _$UserAccountInfoToJson(UserAccountInfo instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
      'isAdmin': instance.isAdmin,
      'photo': _photoToJson(instance.photo),
    };

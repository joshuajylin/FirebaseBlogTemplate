
import 'package:json_annotation/json_annotation.dart';

part 'UserProfile.g.dart';

@JsonSerializable()
class UserProfile {
  bool isAdmin;

  UserProfile({
    this.isAdmin = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

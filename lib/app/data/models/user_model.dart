import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String? phoneNumber;

  @HiveField(1)
  final String? name;

  @HiveField(2)
  final String? email;

  @HiveField(3)
  final String? profileImage; // Now stores Cloudinary URL instead of local path

  @HiveField(4)
  final double? latitude;

  @HiveField(5)
  final double? longitude;

  @HiveField(6)
  final bool isLoggedIn;

  @HiveField(7)
  final List<String> galleryImages;

  UserModel({
    this.phoneNumber,
    this.name,
    this.email,
    this.profileImage,
    this.latitude,
    this.longitude,
    this.isLoggedIn = false,
    this.galleryImages = const [],
  });

  UserModel copyWith({
    String? phoneNumber,
    String? name,
    String? email,
    String? profileImage,
    double? latitude,
    double? longitude,
    bool? isLoggedIn,
    List<String>? galleryImages,
  }) {
    return UserModel(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      galleryImages: galleryImages ?? this.galleryImages,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        phoneNumber: json['phoneNumber'] as String?,
        name: json['name'] as String?,
        email: json['email'] as String?,
        profileImage: json['profileImage'] as String?,
        latitude: json['latitude'] as double?,
        longitude: json['longitude'] as double?,
        isLoggedIn: json['isLoggedIn'] as bool? ?? false,
        galleryImages: List<String>.from(json['galleryImages'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'name': name,
        'email': email,
        'profileImage': profileImage,
        'latitude': latitude,
        'longitude': longitude,
        'isLoggedIn': isLoggedIn,
        'galleryImages': galleryImages,
      };
} 
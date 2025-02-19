import 'location.dart';

class UserDetails {
  final String? name;
  final String? email;
  final String? profileImage;
  final String phone;
  final Location location;

  UserDetails({
    this.name,
    this.email,
    this.profileImage,
    required this.phone,
    required this.location,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      name: json['name'],
      email: json['email'],
      profileImage: json['profileImage'],
      phone: json['phone'] ?? '',
      location: Location.fromJson(json['location'] ?? {'latitude': 0.0, 'longitude': 0.0}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'location': location.toJson(),
    };
  }
} 
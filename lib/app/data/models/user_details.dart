import 'location.dart';

class UserDetails {
  final String name;
  final String email;
  final String phone;
  final String image;
  final Location location;

  UserDetails({
    required this.name,
    required this.email,
    required this.phone,
    required this.image,
    required this.location,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      image: json['image'] ?? '',
      location: Location.fromJson(json['location'] ?? {'latitude': 0.0, 'longitude': 0.0}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'image': image,
      'location': location.toJson(),
    };
  }
} 
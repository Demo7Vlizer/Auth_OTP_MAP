import 'user_details.dart';

class OtpRecord {
  final String id;
  final String phoneNumber;
  final String otp;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final UserDetails? userDetails;

  OtpRecord({
    required this.id,
    required this.phoneNumber,
    required this.otp,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.userDetails,
  });

  factory OtpRecord.fromJson(Map<String, dynamic> json) {
    return OtpRecord(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      otp: json['otp'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      latitude: json['location']?['latitude']?.toDouble(),
      longitude: json['location']?['longitude']?.toDouble(),
      userDetails: json['userDetails'] != null 
          ? UserDetails.fromJson(json['userDetails']) 
          : null,
    );
  }
} 
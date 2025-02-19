import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';
import '../config/cloudinary_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

class CloudinaryService {
  static CloudinaryService? _instance;
  late final CloudinaryPublic _cloudinary;

  // Singleton pattern
  static CloudinaryService get instance {
    _instance ??= CloudinaryService._();
    return _instance!;
  }

  CloudinaryService._() {
    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,  // Use the upload preset instead of API secret
      cache: false,
    );
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      print('Starting image upload to Cloudinary...'); // Debug log
      print('Using cloud name: ${CloudinaryConfig.cloudName}');
      print('Using upload preset: ${CloudinaryConfig.uploadPreset}');
      print('File path: ${imageFile.path}'); // Debug log
      
      if (!await imageFile.exists()) {
        throw Exception('File does not exist at path: ${imageFile.path}');
      }

      final fileSize = await imageFile.length();
      print('File size: ${fileSize / 1024}KB'); // Debug log
      
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image size too large. Please choose an image under 10MB.');
      }

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'samples/ecommerce', // From your screenshot
          tags: ['auth_images'],
        ),
      );
      
      print('Upload successful: ${response.secureUrl}'); // Debug log
      return response.secureUrl;
    } catch (e) {
      print('Detailed Cloudinary upload error: $e'); // More detailed error log
      print('Stack trace: ${StackTrace.current}'); // Stack trace for debugging
      
      if (e.toString().contains('NetworkError')) {
        throw Exception('Network error. Please check your internet connection.');
      }
      
      // More specific error handling
      if (e.toString().contains('400')) {
        throw Exception('Invalid upload configuration. Please check your Cloudinary settings.');
      }
      
      rethrow; // This will help see the actual error
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract public ID from Cloudinary URL
      final Uri uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final publicId = pathSegments.sublist(pathSegments.length - 2).join('/').split('.').first;
      
      print('Attempting to delete image with public ID: $publicId');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/1000; // Unix timestamp in seconds
      final signature = generateSignature(publicId, timestamp);
      
      final deleteUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/destroy'
      );

      final response = await http.post(deleteUrl, body: {
        'public_id': publicId,
        'api_key': CloudinaryConfig.apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
      });
      
      print('Delete response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Failed to delete from Cloudinary: $e');
      return false;
    }
  }

  String generateSignature(String publicId, int timestamp) {
    // Create the string to sign exactly as Cloudinary expects
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp';
    
    // Generate the SHA-1 signature using the API secret
    final signature = crypto.sha1
        .convert(utf8.encode(stringToSign + CloudinaryConfig.apiSecret))
        .toString();
        
    print('String to sign: $stringToSign');
    print('Generated signature: $signature');
    
    return signature;
  }
} 